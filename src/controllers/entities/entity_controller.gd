class_name EntityController extends Controller

# components


## evaluates combat between a source and target entity
func evaluate_combat(src: Entity, target: Entity):
	var target_health = target.data.stats.health
	var src_attack = src.data.stats.attack
	var src_hit = src.data.stats.hit_chance
	var src_crit = src.data.stats.crit_chance
	var src_crit_bonus = src.data.stats.crit_bonus
	# evaluate if enemy attack is hit
	var r = randf_range(0, 1)
	# if random number r is below hit threshold
	var is_crit = false
	if r <= src_hit:
		# attack is a hit,
		# if attack is crit,
		if r <= src_crit:
			# calculate crit
			src_attack *= src_crit_bonus
			is_crit = true
	# if miss,
	else:
		# attack is 0 this turn
		src_attack = 0

	# update player health
	target_health -= floor(src_attack)
	target.data.stats.health = target_health

	# update last hit taken amount if Player
	if target is Player:
		if src_attack >= target.data.stats.largest_hit:
			target.data.stats.largest_hit = src_attack

	# log results
	if src_attack != 0:
		if is_crit:
			self.FileLogger.log_message(self , (src.name + " crits " + target.name + " for "
				+ str(src_attack) + " dmg."),
				"COMBAT"
			)
		else:
			self.FileLogger.log_message(self , (src.name + " hits " + target.name + " for "
				+ str(src_attack) + " dmg."),
				"COMBAT"
			)
		self.FileLogger.log_message(self , target.name + " health: " + str(target_health),
			"COMBAT"
		)
	else:
		self.FileLogger.log_message(self , (src.name + " misses " + target.name + "."), "COMBAT")
