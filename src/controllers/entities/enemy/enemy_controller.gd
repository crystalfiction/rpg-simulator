extends Controller

# references
var FileLogger
var enemy_scene = preload("res://src/entities/enemies/enemy.tscn")
var actions_controller_script = preload("res://src/controllers/entities/actions_controller.gd")

var actions_controller: Controller

# components
var eid_ref = 0
var cycle_complete = false

var enemies = []


# spawns n enemies and returns them
func spawn_enemies(n: int = 1) -> Array:
	var new_enemies = []
	for e in range(n):
		var new_enemy = _init_enemy_entity()
		new_enemy.data.stats = _calculate_stats(new_enemy.data.stats)
		new_enemies.append(new_enemy)
		self.enemies.append(new_enemy)
	return new_enemies


func _calculate_stats(stats: Dictionary) -> Dictionary:
	var map_level = self.world.data.terrain.map_count
	stats.level = map_level
	stats.resilience = stats.level
	stats.strength = stats.level
	stats.health += floor(
		(stats.resilience * PI)
	)
	stats.attack = floor(
		(stats.strength * PI)
	)
	return stats


# initializes enemy entity
func _init_enemy_entity():
	var world_controller = self.world.data.controller
	var new_enemy = self.enemy_scene.instantiate()
	# metadata
	new_enemy.data.uid = world_controller.uid_ref
	new_enemy.data.eid = self.eid_ref
	new_enemy.name = "enemy_" + str(new_enemy.data.eid)
	new_enemy.data.world = self.world
	new_enemy.data.controller = self

	var e = new_enemy
	add_child(new_enemy)
	
	# update uid ref
	world_controller.uid_ref += 1
	self.eid_ref += 1

	return e


func evaluate_combat(e: Enemy, p: Player):
	var e_health = e.data.stats.health
	var p_attack = p.data.stats.attack
	var p_hit = p.data.stats.hit_chance
	# evaluate if player attack is hit
	var r = randf_range(0, 1)
	# if random number r is below hit threshold
	if r <= p_hit:
		# attack is a hit
		e_health -= p_attack
		e.data.stats.health = e_health
	# if miss,
	else:
		# attack is 0 this turn
		p_attack = 0
	
	FileLogger.log_message(self , (
		p.name + " hits " + e.name + " for " +
		str(p_attack) + " dmg."),
		"COMBAT"
	)
	FileLogger.log_message(self , e.name + " health: " + str(e_health),
		"COMBAT"
	)

	# check enemy state after combat
	_check_enemies(self.enemies)


func _check_enemies(enemy_array: Array):
	# loop through enemies
	for e in enemy_array:
		# if enemy health is 0 or below
		if e.data.stats.health <= 0:
			# if enemy isn't already queued for deletion,
			if !e.is_queued_for_deletion():
				# queue for deletion
				e.queue_free()
				# erase from array
				enemy_array.erase(e)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get FileLogger
	self.FileLogger = $"/root/FileLogger"


# determines and processes enemy logic for a single time cycle
func _process_cycle(enemy_array: Array):
	# only evaluate if time cycling
	var time_controller = self.world.data.controller.time_controller
	if time_controller.cycling:
		_check_enemies(enemy_array)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process enemy cycle
	_process_cycle(self.enemies)
