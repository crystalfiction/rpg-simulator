class_name Action extends RefCounted

# components
var Type: ActionType
enum ActionType {
	IDLE,
	FIND,
	INTERACT,
}
# components
var src = null # the source of the action


# returns the current Action's ActionType value for type validation
func get_action_type():
	var curr_type = self.Type
	return curr_type

# returns the current Action's ActionType string
func get_action_string():
	var curr_type = self.Type
	var key = self.ActionType.find_key(curr_type)
	return key

# initialize data before _ready
func _init() -> void:
	pass
