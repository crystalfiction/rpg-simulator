class_name AttackAction extends Action

var Attack: AttackType
enum AttackType {
	BASIC,
}

func get_attack_type() -> AttackType:
	var curr_type = self.Attack
	return curr_type

func get_attack_type_string() -> String:
	var curr_type = self.Attack
	var key = self.AttackType.find_key(curr_type)
	return key