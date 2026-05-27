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
		"level": 1,
		"exp": 0,
		"exp_cap": 20,
		## TODO: classes
	},
	"actions": {
		"action": null,
		"last_action": null,
		## TODO: abilities
	},
	## TODO: resources
	## TODO: encounters
	## TODO: items
}
