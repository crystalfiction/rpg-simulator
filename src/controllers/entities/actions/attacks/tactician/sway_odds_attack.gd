class_name SwayOddsAttack extends AttackAction

# components
var init_data = {
    "multiplier": 1.0,
    "cooldown": 1,
    "duration": 0,
}


func calculate_multiplier():
    # initialize multiplier
    var multiplier: float = self.data.multiplier
    var crit_bonus: float = self.data.src.data.stats.crit_bonus
    var crit_chance: float = self.data.src.data.stats.crit_chance
    var dodge_chance: float = self.data.src.data.stats.dodge_chance
    # calculate bonus
    var bonus: float = snapped(
        (dodge_chance + ((crit_bonus - 1) / 2) + crit_chance),
        0.01)

    # apply bonus
    self.data.multiplier += snapped(bonus, 0.01)
    var curr_health: float = self.data.src.data.stats.health
    var max_health: float = self.data.src.data.stats.max_health
    var new_health: float = curr_health + (curr_health * ((self.data.multiplier - 1) / 10))
    self.data.src.data.stats.health = clamp(new_health, 0, max_health)

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