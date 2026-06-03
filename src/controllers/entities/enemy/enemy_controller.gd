extends EntityController

# references
var FileLogger
var enemy_scene = preload("res://src/entities/enemies/enemy.tscn")
var enemies = []
# components
var eid_ref = 0
var cycle_complete = false


# Enemy Actions


# Enemy Stats

## calculates enemy stats on spawn
func _calculate_stats(stats: Dictionary) -> Dictionary:
	var map_level = self.world.data.terrain.map_count
	stats.level = map_level
	# increment attributes
	stats.resilience = stats.level
	stats.strength = stats.level
	stats.health += stats.resilience * 10 * (stats.level * 0.5)
	stats.attack += stats.strength * (stats.level * 0.5)
	return stats

# Enemy Initialization

## spawns n enemy entities and returns them in an erray
func spawn_enemies(n: int = 1) -> Array:
	var new_enemies = []
	for e in range(n):
		var new_enemy = _init_enemy_entity()
		new_enemy.data.stats = _calculate_stats(new_enemy.data.stats)
		new_enemies.append(new_enemy)
		self.enemies.append(new_enemy)
	return new_enemies

## initializes enemy entity
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"

# Enemy Processing

## checks enemy defeat conditions and deletes entity object if met
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
