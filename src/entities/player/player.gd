class_name Player extends Entity

# refs
var init_player: Resource = preload("res://src/entities/player/player.tscn")

# components
var Class: PlayerClass
enum PlayerClass {
	BASE
}

var player_data: Dictionary = {
	"world": "",
	"grid_idx": Vector2i(0, 0),
	"stats": {},
	"skills": {
		"UNARMED": {
			"level": 0,
			"exp": 0,
			"cap": 0,
		},
	},
	"actions": {
		"controller": "",
		"action": null,
		"history": [],
	},
	"resources": {
		"food": 0,
		"surplus": 0,
	},
	"encounters": {
		"active": false,
		"done": []
	},
	"inventory": {
		"equipped": {
			"weapon": null,
		},
	}
}

## initializes the entity as scene
func init_scene() -> Sprite2D:
	var new_scene: Sprite2D = self.init_player.instantiate()
	new_scene.data = self.data
	return new_scene

## initializes the entity data
func _init() -> void:
	self.Type = EntityType.PLAYER
	for k in self.player_data:
		self.data[k] = player_data[k]