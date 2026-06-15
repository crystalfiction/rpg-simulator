class_name Enemy extends Entity

# components
var init_enemy: Resource = preload("res://src/entities/enemies/enemy.tscn")
var init_data: Dictionary = {
	"world": "",
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 0,
		"health": 0,
		"max_health": 0,
		"base_health": 100,
		"attack": 0,
		"base_attack": 5,
		"hit_chance": 0.66,
		"crit_chance": 0.11,
		"crit_bonus": 1.50,
		"dodge_chance": 0.05,
		"stamina": 0,
		"strength": 0,
		"perception": 0,
	},
	"actions": {
		"controller": "",
		"action": null,
	},
	"encounters": {
		"active": false,
	},
	"inventory": {
		"equipped": {
			"weapon": null,
			"head": null,
			"chest": null,
			"legs": null,
			"feet": null
		},
	}
}


## initializes the entity scene
func init_scene() -> Sprite2D:
	var new_scene = self.init_enemy.instantiate()
	return new_scene

## initializes the entity
func _init() -> void:
	self.Type = EntityType.ENEMY
	_traverse_data(self.data, self.init_data)