class_name BasicAttack extends AttackAction

# components
var init_data = {
    "multiplier": 1.0,
    "cooldown": 0,
    "duration": 0,
}


# initialize data before _ready
func _init() -> void:
    super ()
    # init action type
    self.Type = self.ActionType.ATTACK
    # init attack type
    self.Attack = self.AttackType.BASIC
    # init data
    for k in self.init_data:
        self.data[k] = self.init_data[k]