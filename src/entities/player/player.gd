class_name Player extends Entity

# refs
var world: World

# components
var data = {
	"uid": 0,
	"pid": 0,
	"controller": "",
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 0,
		"exp": 0,
		"exp_cap": 0,
		## TODO: classes
	},
	"actions": {
		"controller": "",
		"action": "",
		"last_action": "",
		## TODO: abilities
	},
	## TODO: resources
	## TODO: encounters
	## TODO: items
}
