class_name Enemy extends Entity

# components
var data = {
	"uid": 0,
	"controller": "",
	"world": "",
	"grid_idx": Vector2i(0, 0),
	"stats": {
		"level": 0,
		"health": 0,
		"max_health": 0,
		"base_health": 100,
		"attack": 0,
		"base_attack": 5,
		"hit_chance": 0.66,
		"crit_chance": 0.11,
		"crit_bonus": 1.50,
		"dodge_chance": 0.05,
		"stamina": 0,
		"strength": 0,
		"agility": 0,
	},
	"actions": {
		"controller": "",
		"action": null,
		"history": [],
	},
}