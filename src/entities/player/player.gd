class_name Player extends Entity

# components
var data = {
	"uid": 0,
	"controller": "",
	"pid": 0,
	"grid_idx": Vector2i(0, 0),
	"stats": {
		# written on init
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
	}
}

var Class: PlayerClass
enum PlayerClass {
	BASE,
}
var class_objs = {
	0: BaseClass,
}

## gets and returns the class's initial stats from script object
func _get_class_data(player_class: PlayerClass) -> Dictionary:
	# create new class object
	var new_obj = self.class_objs[player_class].new()
	var class_stats = new_obj.stats
	return class_stats

## returns the current Player's PlayerClass value for type validation
func get_player_class() -> PlayerClass:
	var curr_class = self.Class
	return curr_class

# returns the current player's PlayerClass string
func get_player_class_string() -> String:
	var curr_class = self.Class
	var key = self.PlayerClass.find_key(curr_class)
	return key

## sets player.Class to the passed player_class before entering tree
func init_player(
	player_class: PlayerClass = PlayerClass.BASE,
):
	# set player class
	self.Class = player_class
	# overwrite stats with class stats
	var new_stats = _get_class_data(self.Class)
	self.data.stats = new_stats
