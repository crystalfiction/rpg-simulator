class_name PersistAttack extends AttackAction

# components
var init_data = {
    "multiplier": 1.0,
    "cooldown": 1,
    "duration": 0,
}


func calculate_multiplier():
    # initialize multiplier
    var multiplier: float = self.data.multiplier
    var max_health: float = self.data.src.data.stats.max_health
    var curr_health: float = self.data.src.data.stats.health
    var curr_food: float = self.data.src.data.resources.food
    var food_cost: float = curr_food * 0.01
    var new_food = curr_food - food_cost
    # calculate bonus
    var bonus: float = snapped(
        (max_health / (curr_food + curr_health + max_health)),
        0.01)
    # sacrifice 1% of current food
    if new_food > 0:
        self.data.src.data.resources.food = snapped(new_food, 0.01)

    # apply bonus
    self.data.multiplier += snapped(bonus, 0.01)

# initialize data before _ready
func _init() -> void:
    super ()
    # init action type
    self.Type = self.ActionType.ATTACK
    # init attack type
    self.Attack = self.AttackType.PERSIST
    # init data
    for k in self.init_data:
        self.data[k] = self.init_data[k]