class_name EntityController extends Controller


## evaluates combat between a source and target entity
func evaluate_combat(src: Entity, target: Entity):
	var src_health = src.data.stats.health
	var target_attack = target.data.stats.attack
	var target_hit = target.data.stats.hit_chance
	var target_crit = target.data.stats.crit_chance
	var target_crit_bonus = target.data.stats.crit_bonus
	# evaluate if enemy attack is hit
	var r = randf_range(0, 1)
	# if random number r is below hit threshold
	var is_crit = false
	if r <= target_hit:
		# attack is a hit,
		# if attack is crit,
		if r <= target_crit:
			# calculate crit
			target_attack *= target_crit_bonus
			is_crit = true
	# if miss,
	else:
		# attack is 0 this turn
		target_attack = 0
	
	# update player health
	src_health -= target_attack
	src.data.stats.health = src_health

	# update last hit taken amount if Player
	if src is Player:
		if target_attack >= src.data.stats.last_hit:
			src.data.stats.last_hit = target_attack

	# log results
	if target_attack != 0:
		if is_crit:
			self.FileLogger.log_message(self , (target.name + " crits " + src.name + " for "
				+ str(target_attack) + " dmg."),
				"COMBAT"
			)
		else:
			self.FileLogger.log_message(self , (target.name + " hits " + src.name + " for "
				+ str(target_attack) + " dmg."),
				"COMBAT"
			)
		self.FileLogger.log_message(self , src.name + " health: " + str(src_health),
			"COMBAT"
		)
	else:
		self.FileLogger.log_message(self , (target.name + " misses " + src.name + "."), "COMBAT")
