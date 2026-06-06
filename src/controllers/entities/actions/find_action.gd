class_name FindAction extends Action

# components
var Objective: FindType
enum FindType {
    RESOURCE,
}


func get_objective_string() -> String:
    var objective = self.Objective
    var key = FindType.find_key(objective)
    return key

# initialize data before _ready
func _init(objective: FindType) -> void:
    self.Type = self.ActionType.FIND
    self.Objective = objective
