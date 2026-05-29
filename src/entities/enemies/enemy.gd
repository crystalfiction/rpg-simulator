class_name Enemy extends Entity

# components
var data = {
	"uid": 0,
	"eid": 0,
	"controller": "",
	"parent": "", # the parent entity to the enemy
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 0,
		"health": 100,
		## TODO: classes
	},
	"actions": {
		"controller": "",
		"action": null,
		"last_action": null,
		## TODO: abilities
	},
	"resources": {},
	## TODO: items
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
