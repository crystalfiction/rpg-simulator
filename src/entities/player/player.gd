class_name Player extends Entity

# refs
var init_player: Resource = preload("res://src/entities/player/player.tscn")

# components
var Class: PlayerClass
enum PlayerClass {
	BASE,
	WANDERER,
	BRUTE,
	TACTICIAN,
}
var PlayerClasses = {
	0: BaseClass,
	1: WandererClass,
	2: BruteClass,
	3: TacticianClass,
}

var player_data: Dictionary = {
	"world": "",
	"grid_idx": Vector2i(0, 0),
	"class": null,
	"class_v": "",
	"stats": {
		# initialized by PlayerClass
	},
	"actions": {
		"controller": null,
		"action": null,
		"last_action": "",
		"abilities": [
			HeavyAttack,
		],
		"metrics": {
			# "HITS": 0,
			# "MISSES": 0,
			# "CRITS": 0,
			# "DODGES": 0,
		},
		"last_stand": true,
	},
	"skills": {},
	"resources": {
		"food": 0,
		"total": 0
	},
	"encounters": {
		"active": false,
		"done": 0
	},
	"inventory": {
		"manager": null,
		"equipped": {
			"weapon": null,
			"head": null,
			"chest": null,
			"legs": null,
			"feet": null
		},
	}
}


func get_player_class() -> PlayerClass:
	var curr_class = self.Class
	return curr_class

func get_player_class_string() -> String:
	var curr_class = self.Class
	var key = PlayerClass.find_key(curr_class)
	return key

## initializes the entity as scene
func init_scene() -> Sprite2D:
	var new_scene: Sprite2D = self.init_player.instantiate()
	return new_scene

## initializes the entity data
func _init() -> void:
	self.Type = EntityType.PLAYER
	self.data = _traverse_data(self.data, self.player_data)
