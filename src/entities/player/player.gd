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
	"world": null,
	"grid_idx": Vector2i(0, 0),
	"class": null,
	"class_v": "",
	"stats": {
		# initialized by PlayerClass
	},
	"actions": {
		"controller": null,
		"action": null,
		"action_v": null,
		"last_action": null,
		"abilities": [],
		"metrics": {
			# "HITS": 0,
			# "MISSES": 0,
			# "CRITS": 0,
			# "DODGES": 0,
			# "highest_map: 0,
		},
		"last_stand": true, # whether or not last stand is available
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
		"controller": null,
		"equipped": {
			"weapon": null,
			"head": null,
			"chest": null,
			"legs": null,
			"feet": null
		},
		"bags": [],
		"items": 0,
	}
}


func get_player_class() -> PlayerClass:
	return self.Class


func get_player_class_string() -> String:
	var key = PlayerClass.find_key(self.Class)
	return key


## initializes the entity as scene
func init_scene() -> Sprite2D:
	var new_scene: Sprite2D = self.init_player.instantiate()
	return new_scene


## initializes the entity data
func _init() -> void:
	self.Type = EntityType.PLAYER
	self.data = _traverse_data(self.data, self.player_data)
