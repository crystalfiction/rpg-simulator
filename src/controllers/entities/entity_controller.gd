class_name EntityController extends Controller

# components


## evaluates combat between a source and target entity
func evaluate_combat(action: Action):
	var src_attack = action.src.data.stats.attack
	var src_hit = action.src.data.stats.hit_chance
	var src_crit = action.src.data.stats.crit_chance
	var src_crit_bonus = action.src.data.stats.crit_bonus
	var target_health = action.target.data.stats.health
	var target_dodge = action.target.data.stats.dodge_chance
	# evaluate if enemy attack is hit
	var r = randf_range(0, 1)
	# if random number r is below hit threshold
	var result = ""
	# if attack is a hit,
	if r <= src_hit:
		# attack is hit
		result = "hits"
		
		# if hit dodged,
		if r <= target_dodge:
			# no hit
			result = "dodges"
			src_attack = 0
		
		# if still hit, check if crit,
		elif r <= src_crit:
			# calculate crit
			result = "crits"
			src_attack *= src_crit_bonus

	# if miss,
	else:
		# no hit
		result = "misses"
		src_attack = 0
	
	# update target health
	target_health -= floor(src_attack)
	action.target.data.stats.health = target_health

	# update last hit taken amount if Player
	if action.target is Player:
		if src_attack >= action.target.data.stats.largest_hit:
			action.target.data.stats.largest_hit = src_attack

	# log results
	if result == "dodges":
		FileLogger.log_message(self ,
			action.target.name + " " + result + " " + action.src.name + "'s attack",
		"COMBAT")
	else:
		if result == "misses":
			FileLogger.log_message(self ,
				action.src.name + " " + result + " " + action.target.name,
			"COMBAT")
		else:
			FileLogger.log_message(self ,
				action.src.name + " " + result + " " + action.target.name + " for " +
				str(src_attack),
			"COMBAT")

func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"