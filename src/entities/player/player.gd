class_name Player extends Entity

# refs

# components
var init_data = {
	# "uid": 0,
	# "controller": "",
	"pid": 0,
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 0,
		"exp": 0,
		"exp_cap": 0,
		"exp_step": 0,
		"health": 0,
		"base_health": 150,
		"max_health": 100,
		"regen_rate": 0.33,
		"attack": 0,
		"base_attack": 10,
		"hit_chance": 0.66,
		"crit_chance": 0.11,
		"crit_bonus": 1.50,
		"resilience": 0,
		"strength": 0,
		"wisdom": 0,
		"largest_hit": 0,
	},
	"actions": {
		"controller": "",
		"action": null,
		"history": [],
	},
	"resources": {
		"food": 0
	},
	"encounters": {
		"active": false,
		"done": []
	}
	## TODO: classes
	## TODO: abilities
	## TODO: items
}

## define entity class data before _ready
func _init() -> void:
	# add data to entity data dict
	for k in self.init_data:
		self.data[k] = self.init_data[k]