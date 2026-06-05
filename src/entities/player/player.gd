class_name Player extends Entity

# components
## TODO: migrate cumbersome stats to external data resource
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
		"max_health": 0,
		"base_health": 150,
		"regen_rate": 0.3,
		"attack": 0,
		"base_attack": 10,
		"hit_chance": 0.66,
		"crit_chance": 0.11,
		"crit_bonus": 1.50,
		"dodge_chance": 0.05,
		"stamina": 0,
		"strength": 0,
		"agility": 0,
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

var Class: PlayerClass
enum PlayerClass {
	WANDERER,
}


# returns the current Player's PlayerClass value for type validation
func get_player_class():
	var curr_class = self.Class
	return curr_class

## define entity class data
func _init() -> void:
	# add init data to entity data dict
	for k in self.init_data:
		# init data
		self.data[k] = self.init_data[k]
