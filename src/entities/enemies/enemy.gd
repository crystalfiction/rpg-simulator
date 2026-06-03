class_name Enemy extends Entity

# components
var init_data = {
	# "uid": 0,
	# "controller": "",
	"eid": 0,
	"parent": "", # the parent entity to the enemy
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 1,
		"health": 100,
		"attack": 5,
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
	"resources": {},
	## TODO: items
}

## define entity class data before _ready
func _init() -> void:
	# add data to entity data dict
	for k in self.init_data:
		self.data[k] = self.init_data[k]