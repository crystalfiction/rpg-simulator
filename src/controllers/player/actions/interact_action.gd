class_name InteractAction extends Action

# components
var Objective: InteractTarget
enum InteractTarget {
    RESOURCE,
}

var has_resources = false
var did_encounter = false


# initializes action as type
func _init() -> void:
    self.Type = self.ActionType.INTERACT