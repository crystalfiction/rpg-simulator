class_name Action extends RefCounted

# components
var Type: ActionType
enum ActionType {
	FIND,
	INTERACT,
	ATTACK,
}

var data: Dictionary = {
	"src": null,
	"target": null,
	"done": false
}

# returns the current Action's ActionType value for type validation
func get_action_type() -> ActionType:
	var curr_type = self.Type
	return curr_type

# returns the current Action's ActionType string
func get_action_string() -> String:
	var curr_type = self.Type
	var key = self.ActionType.find_key(curr_type)
	return key
