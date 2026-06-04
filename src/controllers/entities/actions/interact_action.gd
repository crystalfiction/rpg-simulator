class_name InteractAction extends Action

# components
var Target: InteractTarget
enum InteractTarget {
    RESOURCE,
}


# initialize data before _ready
func _init(target_type: InteractTarget) -> void:
    # update dependency vars
    self.Type = self.ActionType.INTERACT
    self.Target = target_type
