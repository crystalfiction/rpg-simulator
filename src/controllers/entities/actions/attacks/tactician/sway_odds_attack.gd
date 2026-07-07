class_name SwayOddsAttack extends AttackAction

# components
var init_data = {
    "multiplier": 1.5,
    "cooldown": 2,
    "duration": 0,
}


func calculate_multiplier():
    # initialize multiplier
    pass

# initialize data before _ready
func _init() -> void:
    super()
    # init action type
    self.Type = self.ActionType.ATTACK
    # init attack type
    self.Attack = self.AttackType.SWAYODDS
    # init data
    for k in self.init_data:
        self.data[k] = self.init_data[k]