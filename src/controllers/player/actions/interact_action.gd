class_name InteractAction extends Action

# components
var Objective: InteractTarget
enum InteractTarget {
    RESOURCE,
}


# initializes action as type
func _init() -> void:
    self.Type = self.ActionType.INTERACT