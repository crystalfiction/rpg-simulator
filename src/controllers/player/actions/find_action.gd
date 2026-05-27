class_name FindAction extends Action

# components
var Objective: FindTarget
enum FindTarget {
    RESOURCE,
}


# initializes action as type
func _init(objective: FindTarget) -> void:
    # assert ActionType
    self.Type = self.ActionType.FIND

    # parse find_target
    self.Objective = objective