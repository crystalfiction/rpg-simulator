class_name BaseClass extends Player

# components
var class_data: Dictionary = {
	"stats": {
		"level": 0,
		"exp": 0,
		"exp_cap": 0,
		"exp_step": 0,
		"health": 0,
		"max_health": 0,
		"base_health": 100,
		"regen_rate": 0.165,
		"attack": 0,
		"base_attack": 5,
		"largest_hit": 0,
		"largest_taken": 0,
		"hit_chance": 0.66,
		"crit_chance": 0.11,
		"crit_bonus": 1.50,
		"dodge_chance": 0.05,
		"stamina": 0,
		"strength": 0,
		"perception": 0,
	},
}

## initializes the entity data
func _init() -> void:
	self.Class = PlayerClass.BASE
	super ()
	for k in self.class_data:
		if k is Dictionary:
			for k_n in self.class_data[k]:
				self.data[k][k_n] = class_data[k][k_n]
		else:
			self.data[k] = class_data[k]
