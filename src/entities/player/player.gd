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
		"exp_cap": 0,
		"health": 0,
		"max_health": 100,
		"attack": 10,
		"hit_chance": 0.75,
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

# when player enters tree,
func _ready() -> void:
	pass