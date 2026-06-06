class_name EntityController extends Controller

# components
var FileLogger

## calculates base experience values for a given stats dictionary
## returns updated stats dictionary
func _calculate_exp(e: Entity) -> Dictionary:
	var stats = e.data.stats
	# if player,
	if e is Player:
		stats.level += 1
		self.exp_step = 10
		# quadratic formula
		# self.exp_cap = self.exp_step * (stats.level ** 2)
		# exponential formula
		self.exp_cap = (self.exp_step) * (stats.level) ** 1.5

		stats.exp_step = self.exp_step
		stats.exp_cap = self.exp_cap
		stats.exp = 0
	
	# if enemy,
	if e is Enemy:
		var map_level = self.world.data.terrain.map_count
		stats.level = map_level

	# return stats dict
	return stats

## calculates base attribute values for a given stats dictionary
## returns updated stats dictionary
func _calculate_attributes(e: Entity) -> Dictionary:
	var stats = e.data.stats
	if e is Player:
		# BASE
		# base stats
		stats.stamina += 1
		stats.strength += 1
		stats.agility += 1

		# players receive bonus stats on every even level
		if stats.level % 2 == 0:
			stats.stamina += 1
			stats.strength += 1
			stats.agility += 1
	
	if e is Enemy:
		# base stats
		stats.stamina += stats.level
		stats.strength += stats.level
		stats.agility += stats.level

	# stamina-based
	stats.max_health = stats.base_health + (stats.stamina * 20)
	stats.health = stats.max_health
	# strength-based
	stats.attack = stats.base_attack + (stats.strength * 2)
	# agility-based
	stats.crit_chance += (stats.agility * 0.0001)
	stats.dodge_chance += (stats.agility * 0.0001)
	
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
	## TODO: account for attack type
	var src_attack = attack.src.data.stats.attack
	var src_hit = attack.src.data.stats.hit_chance
	var src_crit = attack.src.data.stats.crit_chance
	var src_crit_bonus = attack.src.data.stats.crit_bonus
	var target_health = attack.target.data.stats.health
	var target_dodge = attack.target.data.stats.dodge_chance
	# evaluate if enemy attack is hit
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
	
	# update target health
	target_health -= floor(src_attack)
	attack.target.data.stats.health = target_health

	# update last hit taken amount if Player
	if attack.target is Player:
		if src_attack >= attack.target.data.stats.largest_hit:
			attack.target.data.stats.largest_hit = src_attack

	# if target is player,
	if attack.target is Player:
		var p = attack.target
		# check if food surplus,
		if p.data.resources.surplus > 0 && (
				p.data.stats.health < p.data.stats.max_health):
			# increase health by regen_rate
			var regen = p.data.stats.max_health * (p.data.stats.regen_rate)
			var new_health = clamp(
				p.data.stats.health + regen, 0, p.data.stats.max_health)
			p.data.stats.health = new_health
			# reduce resource surplus by 1 if > 0
			p.data.resources.surplus = (
				(p.data.resources.surplus - 1) if (p.data.resources.surplus > 0
				) else (p.data.resources.surplus)
			)

	# log results
	if result == "DODGES":
		FileLogger.log_message(self ,
			attack.target.name + " " + result + " " + attack.src.name + "'s attack",
		"COMBAT")
	else:
		if result == "MISSES":
			FileLogger.log_message(self ,
				attack.src.name + " " + result + " " + attack.target.name,
			"COMBAT")
		else:
			FileLogger.log_message(self ,
				attack.src.name + " " + result + " " + attack.target.name + " for " +
				str(src_attack) + " with " + str(attack.get_attack_type_string()) + " attack",
			"COMBAT")
	
	# flag action complete
	attack.done = true


func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"