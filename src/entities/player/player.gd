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
		"health": 100,
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
		"done": 0
	}
	## TODO: items
}
