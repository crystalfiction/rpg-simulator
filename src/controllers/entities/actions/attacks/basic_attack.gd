class_name BasicAttack extends AttackAction

# components

# initialize data before _ready
func _init() -> void:
    # init action type
    self.Type = self.ActionType.ATTACK
    # init attack type
    self.Attack = self.AttackType.BASIC