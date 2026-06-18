class_name FrenzyAttack extends AttackAction

# components
var init_data = {
    "multiplier": 1.0,
    "cooldown": 1,
    "duration": 0,
}

func calculate_multiplier():
    var curr_health: float = self.data.src.data.stats.health
    var max_health: float = self.data.src.data.stats.max_health
    var health_cost: float = curr_health * 0.01
    var new_health: float = curr_health - health_cost
    var bonus: float = (max_health / (curr_health + max_health))
    # sacrifice health
    if new_health > 0:
        self.data.src.data.stats.health = snapped(new_health, 0.01)

    self.data.multiplier += snapped(bonus, 0.01)

# initialize data before _ready
func _init() -> void:
    super ()
    # init action type
    self.Type = self.ActionType.ATTACK
    # init attack type
    self.Attack = self.AttackType.FRENZY
    # init data
    for k in self.init_data:
        self.data[k] = self.init_data[k]