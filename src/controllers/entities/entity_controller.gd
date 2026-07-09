class_name EntityController extends Controller

# components
var last_cycle: int = 0

func _calculate_skill(skill: Dictionary):
	var step = 10
	var cap = floor((step) * (skill.level ** 2))
	skill.step = step
	skill.cap = cap
	return skill

func _progress_skill(entity: Entity, skill: String):
	if skill not in entity.data.skills:
		var new_skill = {
			"level": 0,
			"exp": 0,
			"step": 0,
			"cap": 0,
			"bonus": 0.0,
			
		}
		entity.data.skills[skill] = new_skill
		entity.data.skills[skill] = _calculate_skill(
			entity.data.skills[skill])
	
	# skill already initialized,
	else:
		entity.data.skills[skill].exp += entity.data.skills[skill].step
		entity.data.skills[skill] = _check_skill(entity.data.skills[skill])

func _check_skill(skill: Dictionary):
	if skill.exp >= skill.cap:
		skill.level += 1
		skill = _calculate_skill(skill)
	return skill


## calculates base experience values for a given stats dictionary
## returns updated stats dictionary
func _calculate_exp(e: Entity) -> Dictionary:
	var stats = e.data.stats
	# if player,
	if e is Player:
		stats.level += 1
		self.exp_step = 10 + stats.level
		# quadratic formula
		self.exp_cap = self.exp_step * (stats.level ** 2)
		# exponential formula
		# self.exp_cap = (self.exp_step) * (stats.level - 1) ** 1.5

		stats.exp_step = self.exp_step
		stats.exp_cap = self.exp_cap
		stats.exp = 0
	
	# if enemy,
	if e is Enemy:
		var map_count = self.world.data.terrain.data.map_count
		stats.level = map_count

	# return stats dict
	return stats

## calculates base attribute values for a given stats dictionary
## returns updated stats dictionary
func _calculate_attributes(e: Entity) -> Dictionary:
	var stats = e.data.stats

	# BASE STATS
	if e is Player:
		stats.stamina += 1
		stats.strength += 1
		stats.perception += 1
	elif e is Enemy:
		stats.stamina += stats.level
		stats.strength += stats.level
		stats.perception += stats.level
	
	# scaling
	# stamina
	var stamina_multi = 10
	var stamina_step = stats.stamina * stamina_multi
	# strength
	var strength_multi = 2
	var strength_step = stats.strength * strength_multi
	# perception
	var perception_multi = 0.001
	var perception_step = stats.perception * perception_multi
	
	# player class bonuses
	if e is Player:
		# regen
		var regen_step = clamp(stats.stamina * 0.001, 0, 1)
		stats.regen_rate += regen_step
		
		# CLASS BONUSES
		# recalculate attribute scaling according to player class
		match e.Class:
			Player.PlayerClass.WANDERER:
				stamina_multi *= 1.5
				stamina_step = stats.stamina * stamina_multi
			Player.PlayerClass.BRUTE:
				strength_multi *= 1.5
				strength_step = stats.strength * strength_multi
			Player.PlayerClass.TACTICIAN:
				perception_multi *= 1.5
				perception_step = stats.perception * perception_multi

	# calculations
	# stamina
	stats.max_health = snapped(stats.base_health + stamina_step, 0.01)
	stats.health = stats.max_health
	# strength
	stats.attack = snapped(stats.base_attack + strength_step, 0.01)
	# perception
	stats.crit_chance = snapped(stats.base_crit + perception_step, 0.001)
	stats.dodge_chance = snapped(stats.base_dodge + perception_step, 0.001)
	
	# return stats
	return stats

## calculates entity exp + stats and returns stats dictionary
## called when entity level up conditions met and on init
func _calculate_stats(e: Entity) -> Dictionary:
	# calculate initial exp stats
	e.data.stats = _calculate_exp(e)
	# increment attributes
	e.data.stats = _calculate_attributes(e)
	# return new stats
	return e.data.stats

## evaluates combat between a source and target entity
func evaluate_combat(attack: AttackAction):
	var src_level = attack.data.src.data.stats.level
	var src_attack = attack.data.src.data.stats.attack
	var src_hit = attack.data.src.data.stats.hit_chance
	var src_crit = attack.data.src.data.stats.crit_chance
	var src_crit_bonus = attack.data.src.data.stats.crit_bonus
	var target_health = attack.data.target.data.stats.health
	var target_armor = attack.data.target.data.stats.armor
	var target_dodge = attack.data.target.data.stats.dodge_chance

	# WEAPONS
	var weapon_equipped = attack.data.src.data.inventory.equipped.weapon != null
	var equipped_weapon = null
	# check if weapon equipped,
	if weapon_equipped:
		equipped_weapon = attack.data.src.data.inventory.equipped.weapon
		# calculate weapon damage
		# weapon damage = the avg between weapon's dmg and 50% src's attack
		var weapon_dmg = snapped(
			(equipped_weapon.data.stats.damage + (src_attack * 0.50)) / 2,
			0.01)
		# if entity has skills,
		if "skills" in attack.data.src.data:
			# calculate skill damage bonus
			var weapon_string = equipped_weapon.get_weapon_class_string()
			var skill_level = attack.data.src.data.skills[weapon_string].level
			# skill damage = skill level divided by 50% weapon damage + 1
			# ensures skill dmg never exceeds weapon dmg
			# 0 dmg weapons (unarmed) receieve the full skill level bonus
			var skill_dmg = snapped((skill_level) / ((weapon_dmg / 2) + 1), 0.01)
			# update attack src weapon skill bonus data
			attack.data.src.data.skills[weapon_string].bonus = skill_dmg + weapon_dmg
			weapon_dmg += skill_dmg

		# add weapon damage to attack damage
		src_attack += weapon_dmg

	# ARMOR
	# account for armor skill if applicable,
	var armor_skill = 0
	var armor_bonus = 0.0
	if "skills" in attack.data.target.data:
		if "ARMOR" in attack.data.target.data.skills:
			armor_skill = attack.data.target.data.skills.ARMOR.level
			armor_bonus = snapped(target_armor * (armor_skill / (target_armor + 1.0)), 0.1)
			attack.data.target.data.skills.ARMOR.bonus = armor_bonus # save only bonus
			target_armor = armor_bonus

	# calculate armor factor
	var base_health = attack.data.target.data.stats.base_health
	var armor_factor = target_armor + base_health + src_level
	# calculate armor reduction
	var armor_reduc = snapped(
		(float(target_armor) / float(armor_factor)),
		0.001
	)
	attack.data.target.data.stats.armor_factor = armor_factor
	attack.data.target.data.stats.armor_reduc = armor_reduc
	# reduce attack by target armor reduction
	src_attack -= (src_attack * armor_reduc)

	# ABILITIES
	# factor in ability damage multiplier
	if attack.has_method("calculate_multiplier"):
		attack.calculate_multiplier()
	var ability_multi = attack.data.multiplier
	FileLogger.log_message(self,
		str(attack.data.src.name) +
		"::ability=" + str(attack.get_attack_type_string()) + "," +
		"multiplier=" + str(ability_multi),
		"COMBAT")
	src_attack = src_attack * ability_multi

	# EVALUATE
	# evaluate result
	var r = randf_range(0, 1)
	# if random number r is below hit threshold
	var result = ""
	# if attack is a hit,
	if r <= src_hit:
		# attack is hit
		result = "HITS"
		# if hit dodged,
		if r <= target_dodge:
			# no hit
			result = "DODGES"
			src_attack = 0
		# if still hit, check if crit,
		elif r <= src_crit:
			# calculate crit
			result = "CRITS"
			src_attack *= src_crit_bonus
	# if miss,
	else:
		# no hit
		result = "MISSES"
		src_attack = 0

	# apply attack
	src_attack = snapped(src_attack, 0.01)
	target_health -= src_attack
	attack.data.target.data.stats.health = snapped(target_health, 0.01)

	# check for ability effects
	if result == "HITS" or result == "CRITS":
		pass

	# update player damage done/taken metrics
	# both hits and crits
	if result == "HITS" || result == "CRITS":
		if attack.data.src is Player:
			var p = attack.data.src
			p.data.stats.total_dmg = snapped(
				p.data.stats.total_dmg + src_attack,
				0.01)
			var time_controller = p.data.controller.parent.time_controller
			var cycles: float = time_controller.cycles
			var seconds: float = floor(cycles / 10.0)
			p.data.stats.dps = snapped(
				p.data.stats.total_dmg / seconds,
				0.01)
			
	# only hits
	if result == "HITS":
		if attack.data.src is Player:
			var p = attack.data.src
			if src_attack >= p.data.stats.largest_hit:
				p.data.stats.largest_hit = snapped(src_attack, 0.01)
	# p target
	if attack.data.target is Player:
		if not result in attack.data.target.data.actions.metrics:
			attack.data.target.data.actions.metrics[result] = 0
		attack.data.target.data.actions.metrics[result] += 1
		var p = attack.data.target
		if src_attack > p.data.stats.largest_taken:
			p.data.stats.largest_taken = snapped(src_attack, 0.01)

	# p source
	if attack.data.src is Player:
		if not result in attack.data.src.data.actions.metrics:
			attack.data.src.data.actions.metrics[result] = 0
		attack.data.src.data.actions.metrics[result] += 1

	# log results
	# dodge,
	if result == "DODGES":
		FileLogger.log_message(self,
			attack.data.target.name +
			"[lv" + str(attack.data.target.data.stats.level) + "] " +
			result + " " +
			attack.data.src.name + "'s attack",
		"COMBAT")
	# miss, hit, crit
	else:
		# miss,
		if result == "MISSES":
			FileLogger.log_message(self,
				attack.data.src.name +
				"[lv" + str(attack.data.src.data.stats.level) + "] " +
				result + " " +
				attack.data.target.name,
			"COMBAT")
		# hit, crit
		else:
			FileLogger.log_message(self,
				attack.data.src.name +
				"[lv" + str(attack.data.src.data.stats.level) + "] " +
				result + " " +
				attack.data.target.name + " for " +
				str(src_attack) + " with " +
				str(attack.get_attack_type_string()) + " attack" +
				(" using " + equipped_weapon.get_weapon_class_string() if weapon_equipped else ""),
			"COMBAT")
	
	# progress armor skill
	if "skills" in attack.data.target.data:
		if (result == "HITS" || result == "CRITS"):
			# check if armor equipped,
			var equipped = false
			for s in Armor.ArmorSlot:
				if s != null:
					var slot_s = s.to_lower()
					if attack.data.target.data.inventory.equipped[slot_s] != null:
						equipped = true

			# if armor equipped in any slot,			
			if equipped:
				# if crit, 2x progress
				if result == "CRITS":
					_progress_skill(attack.data.src, equipped_weapon.get_weapon_class_string())
				_progress_skill(attack.data.target, "ARMOR")

	# progress weapon skill
	if "skills" in attack.data.src.data:
		if (result == "HITS" || result == "CRITS"):
			# if crit, 2x progress
			if result == "CRITS":
				_progress_skill(attack.data.src, equipped_weapon.get_weapon_class_string())
			_progress_skill(attack.data.src, equipped_weapon.get_weapon_class_string())

	# flag action complete
	attack.data.done = true


func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"