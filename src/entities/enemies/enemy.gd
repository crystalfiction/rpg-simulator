class_name Enemy extends Entity

# components
var data = {
	"uid": 0,
	"eid": 0,
	"controller": "",
	"parent": "", # the parent entity to the enemy
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 1,
		"health": 50,
		"resilience": 1,
		"strength": 1,
		"dexterity": 1,
		# "intelligence": 1,
		"attack": 5,
		"hit_chance": 0.75,
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
	pass