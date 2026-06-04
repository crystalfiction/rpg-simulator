class_name FindAction extends Action

# components
var Objective: FindType
enum FindType {
    RESOURCE,
}

var target = null

# initialize data before _ready
func _init(objective: FindType) -> void:
    self.Type = self.ActionType.FIND
    self.Objective = objective
