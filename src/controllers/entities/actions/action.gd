class_name Action extends RefCounted

# components
var Type: ActionType
enum ActionType {
	FIND,
	INTERACT,
	ATTACK,
}

var src = null # the source of the action
var target = null # the target of the action
var done = null # the completion state of the action

# returns the current Action's ActionType value for type validation
func get_action_type():
	var curr_type = self.Type
	return curr_type

# returns the current Action's ActionType string
func get_action_string():
	var curr_type = self.Type
	var key = self.ActionType.find_key(curr_type)
	return key
