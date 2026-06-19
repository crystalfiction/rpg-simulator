class_name EntityController extends Controller

# components
var skill_chance: float = 0.25


func _calculate_skill(skill: Dictionary):
	var step = 10
	var cap = floor((step) * (skill.level ** 2))
	skill.step = step
	skill.cap = cap
	return skill

func _progress_skill(entity: Entity, skill: String):
	if skill not in entity.data.skills:
		var new_skill = {
			"level": 1,
			"exp": 0,
			"step": 0,
			"cap": 0,
			"bonus": 0.0,
			
		}
		entity.data.skills[skill] = new_skill
		entity.data.skills[skill] = _calculate_skill(
			entity.data.skills[skill])
	
	if skill in entity.data.skills:
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
		self.exp_step = 10
		# quadratic formula
		self.exp_cap = self.exp_step * (stats.level ** 2)
		# exponential formula
		# self.exp_cap = (self.exp_step) * (stats.level - 1) ** 1.5

		stats.exp_step = self.exp_step
		stats.exp_cap = self.exp_cap
		stats.exp = 0
	
	# if enemy,
	if e is Enemy:
		var enemy_controller = self.world.data.controller.enemy_controller
		var map_level = self.world.data.terrain.data.map_count
		var enemy_scaling = enemy_controller.enemy_scaling
		stats.level = floori(map_level * enemy_scaling)

	# return stats dict
	return stats

## calculates base attribute values for a given stats dictionary
## returns updated stats dictionary
func _calculate_attributes(e: Entity) -> Dictionary:
	var stats = e.data.stats
	if e is Player:
		# BASE STATS
		stats.stamina += 1
		stats.strength += 1
		stats.perception += 1

		# stamina-based
		var regen_step = clamp(stats.stamina * 0.0001, 0, 1)
		stats.regen_rate += regen_step

		# perception-based
		# var crit_dodge_step = stats.perception * 0.0001
		
		# CLASS BONUSES
		match e.Class:
			Player.PlayerClass.WANDERER:
				stats.stamina += 1
			Player.PlayerClass.BRUTE:
				stats.strength += 1
			Player.PlayerClass.TACTICIAN:
				stats.perception += 1

	if e is Enemy:
		# base stats
		stats.stamina += stats.level
		stats.strength += stats.level
		stats.perception += stats.level

	# stamina-based
	stats.max_health = stats.base_health + (stats.stamina * 10)
	stats.health = stats.max_health
	# strength-based
	stats.attack = stats.base_attack + (stats.strength * 1.5)
	# agility-based
	stats.crit_chance += (stats.perception * 0.0001)
	stats.dodge_chance += (stats.perception * 0.0001)
	
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
		var weapon_dmg = snapped(
			equipped_weapon.data.stats.damage + (src_attack * 0.50) / 2,
			0.01)
		# if entity has skills,
		if "skills" in attack.data.src.data:
			# calculate skill damage bonus
			var weapon_string = equipped_weapon.get_weapon_class_string()
			var skill_level = attack.data.src.data.skills[weapon_string].level
			var skill_bonus = snapped((skill_level) / ((weapon_dmg / 2) + 1), 0.01)
			# update attack src weapon skill bonus data
			attack.data.src.data.skills[weapon_string].bonus = skill_bonus + weapon_dmg
			weapon_dmg += skill_bonus

		# add weapon damage to attack damage
		src_attack += weapon_dmg
	
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

	# ARMOR
	# reduce attack by target armor reduction
	var base_health = attack.data.target.data.stats.base_health
	var armor_factor = target_armor + (base_health * 10) + src_level
	var armor_reduc = snapped(
		(float(target_armor) / float(armor_factor)),
		0.01
	)
	attack.data.target.data.stats.armor_reduc = armor_reduc
	src_attack -= (src_attack * armor_reduc)

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
	target_health -= src_attack
	attack.data.target.data.stats.health = snapped(target_health, 0.01)

	# check for ability effects
	if result == "HITS" or result == "CRITS":
		if attack.get_attack_type() == AttackAction.AttackType.SWAYODDS:
			# apply 'extra' attack
			src_attack *= 2
			target_health -= src_attack

	# update player damage done/taken metrics
	# both hits and crits
	if result == "HITS" || result == "CRITS":
		if attack.data.src is Player:
			var p = attack.data.src
			var avg_dealt: float = p.data.stats.avg_dealt
			var new_avg: float = (avg_dealt + float(src_attack)) / 2
			p.data.stats.avg_dealt = snapped(new_avg, 0.01)
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
			attack.data.target.name + " " + result + " " + attack.data.src.name + "'s attack",
		"COMBAT")
	# miss, hit, crit
	else:
		# miss,
		if result == "MISSES":
			FileLogger.log_message(self,
				attack.data.src.name + " " + result + " " + attack.data.target.name,
			"COMBAT")
		# hit, crit
		else:
			FileLogger.log_message(self,
				attack.data.src.name + " " + result + " " + attack.data.target.name + " for " +
				str(src_attack) + " with " + str(attack.get_attack_type_string()) + " attack" +
				(" using " + equipped_weapon.get_weapon_class_string() if weapon_equipped else ""),
			"COMBAT")
	
	# process weapon skill
	if "skills" in attack.data.src.data && (
		result == "HITS" || result == "CRITS"):
		if r <= self.skill_chance:
			_progress_skill(attack.data.src, equipped_weapon.get_weapon_class_string())

	# flag action complete
	attack.data.done = true


func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"