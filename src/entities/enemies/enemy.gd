class_name Enemy extends Entity

# components
var data: Dictionary
var init_data = {
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

# when this enemy is ready,
func _ready() -> void:
	# initialize data structure
	self.data = self.init_data