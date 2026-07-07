class_name Enemy extends Entity

# components
var init_enemy: Resource = preload("res://src/entities/enemies/enemy.tscn")
var init_data: Dictionary = {
	"world": null,
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 0,
		"health": 0,
		"max_health": 0,
		"base_health": 100,
		"attack": 0,
		"base_attack": 5,
		"armor": 0,
		"armor_factor": 0,
		"armor_reduc": 0.0,
		"hit_chance": 0.66,
		"crit_bonus": 1.50,
		"crit_chance": 0.0,
		"base_crit": 0.11,
		"dodge_chance": 0.0,
		"base_dodge": 0.05,
		"stamina": 0,
		"strength": 0,
		"perception": 0,
	},
	"skills": {},
	"actions": {
		"controller": null,
		"action": null,
		"last_action": null,
	},
	"encounters": {
		"active": false,
	},
	"inventory": {
		"controller": null,
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
	new_scene.data = self.data
	return new_scene

## initializes the entity
func _init() -> void:
	self.Type = EntityType.ENEMY
	_traverse_data(self.data, self.init_data)