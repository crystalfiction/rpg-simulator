class_name Player extends Entity

# refs

# components
var init_data = {
	# "uid": 0,
	# "controller": "",
	"grid_idx": Vector2i(0, 0),
	"pid": 0,
	"stats": {
		"level": 1,
		"exp": 0,
		"exp_cap": 0,
		"health": 0,
		"max_health": 100,
		"attack": 5,
		"last_hit": 0,
		"hit_chance": 0.66,
		"crit_chance": 0.33,
		"crit_bonus": 1.50,
		"resilience": 1,
		"strength": 1,
		## TODO: classes
	},
	"actions": {
		"controller": "",
		"action": null,
		"last_action": null,
		## TODO: abilities
	},
	"resources": {
		"food": 0
	},
	"encounters": {
		"active": false,
		"done": []
	}
	## TODO: items
}

## define entity class data before _ready
func _init() -> void:
	# add data to entity data dict
	for k in self.init_data:
		self.data[k] = self.init_data[k]