class_name TacticianClass extends Resource

# components
var stats = {
	"level": 0,
	"exp": 0,
	"exp_cap": 0,
	"exp_step": 0,
	"health": 0,
	"max_health": 0,
	"base_health": 100,
	"regen_rate": 0.20,
	"attack": 0,
	"base_attack": 5,
	"dps": 0.0,
	"total_dmg": 0.0,
	"largest_hit": 0.0,
	"largest_taken": 0.0,
	"hit_chance": 0.66,
	"crit_bonus": 1.50,
	"crit_chance": 0.0,
	"base_crit": 0.11,
	"dodge_chance": 0.0,
	"base_dodge": 0.05,
	"armor": 0,
	"armor_reduc": 0.0,
	"stamina": 0,
	"strength": 0,
	"perception": 0,
}
var class_abilities = [
	SwayOddsAttack
]