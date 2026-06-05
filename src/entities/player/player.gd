class_name Player extends Entity

# components
## TODO: migrate cumbersome stats to external data resource
var init_data = {
	# "uid": 0,
	# "controller": "",
	"pid": 0,
	"grid_idx": Vector2i(0, 0),
	# stats,
	"actions": {
		"controller": "",
		"action": null,
		"history": [],
	},
	"resources": {
		"food": 0
	},
	"encounters": {
		"active": false,
		"done": []
	}
	## TODO: abilities,
	## TODO: items,
}

var Class: PlayerClass
enum PlayerClass {
	BASE,
	WANDERER,
}
var class_objs = {
	0: BaseClass,
	1: WandererClass,
}

## gets and returns the class's initial stats dict from script object
func _get_class_stats(player_class: PlayerClass) -> Dictionary:
	# create new class object
	var new_obj = class_objs[player_class].new()
	var class_stats = new_obj.init_stats
	return class_stats

## returns the current Player's PlayerClass value for type validation
func get_player_class():
	var curr_class = self.Class
	return curr_class

# returns the current player's PlayerClass string
func get_player_class_string():
	var curr_class = self.Class
	var key = self.PlayerClass.find_key(curr_class)
	return key

## sets player.Class to the passed player_class before entering tree,
## and initializes player data structure
func init_player(
	player_class: PlayerClass = PlayerClass.BASE,
):
	# set player class
	self.Class = player_class
	# initialize data structure
	self.data = init_data
	# overwrite stats with class stats
	var new_stats = _get_class_stats(self.Class)
	self.data.stats = new_stats
