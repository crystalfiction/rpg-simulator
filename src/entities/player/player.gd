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
	"class": self.Class,
	"stats": {
		# initialized by PlayerClass
	},
	"actions": {
		"controller": "",
		"action": null,
		"abilities": [
			HeavyAttack,
			BasicAttack
		]
	},
	"skills": {},
	"resources": {
		"food": 0,
		"total": 0
	},
	"encounters": {
		"active": false,
		"done": []
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

func get_class_string() -> String:
	var curr_class = self.Class
	var key = PlayerClass.find_key(curr_class)
	return key

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
