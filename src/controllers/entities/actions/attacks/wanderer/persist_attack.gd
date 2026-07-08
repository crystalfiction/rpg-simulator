class_name PersistAttack extends AttackAction

# components
var init_data = {
    "multiplier": 1.5,
    "cooldown": 2,
    "duration": 0,
}


func calculate_multiplier():
    # initialize multiplier
    var stamina: int = self.data.src.data.stats.stamina
    var stam_bonus: float = clampf(stamina / 100.0, 0, 1)
    self.data.multiplier += stam_bonus


# initialize data before _ready
func _init() -> void:
    super()
    # init action type
    self.Type = self.ActionType.ATTACK
    # init attack type
    self.Attack = self.AttackType.PERSIST
    # init data
    for k in self.init_data:
        self.data[k] = self.init_data[k]