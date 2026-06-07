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
		"agility": 0,
	},
	"actions": {
		"controller": "",
		"action": null,
		"history": [],
	},
}


## initializes the entity scene
func init_scene() -> Sprite2D:
	var new_scene = self.init_enemy.instantiate()
	return new_scene

## initializes the entity
func _init() -> void:
	self.Type = EntityType.ENEMY
	for k in self.init_data:
		self.data[k] = init_data[k]