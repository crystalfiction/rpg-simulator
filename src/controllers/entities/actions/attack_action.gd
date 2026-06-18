class_name AttackAction extends Action

var Attack: AttackType
enum AttackType {
	BASIC,
	HEAVY,
	PERSIST,
	FRENZY,
	GAMBLE,
}

var attack_data: Dictionary = {
    "multiplier": 0.0,
    "cooldown": 0,
	"duration": 0,
}


func get_attack_type() -> AttackType:
	var curr_type = self.Attack
	return curr_type

func get_attack_type_string() -> String:
	var curr_type = self.Attack
	var key = self.AttackType.find_key(curr_type)
	return key

func _init() -> void:
	for k in self.attack_data:
		self.data[k] = self.attack_data[k]