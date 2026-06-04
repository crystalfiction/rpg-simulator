extends EntityController

# references
var FileLogger
var enemy_scene = preload("res://src/entities/enemies/enemy.tscn")
# components
var eid_ref = 0

var enemies = []


# Enemy Actions


# Enemy Stats

func _calculate_attributes(stats: Dictionary):
	var map_level = self.world.data.terrain.map_count
	stats.level = map_level
	stats.resilience = stats.level
	stats.strength = stats.level
	stats.max_health = stats.base_health + (stats.resilience * 25)
	stats.health = stats.max_health
	stats.attack = stats.base_attack + (stats.strength * 5)
	return stats

## calculates enemy stats on spawn
func _calculate_stats(stats: Dictionary) -> Dictionary:
	stats = _calculate_attributes(stats)
	# return updated stats dict
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

## initializes a new action controller for the given player entity
func _init_action_controller(e: Enemy) -> ActionController:
	# initialize the controller
	var new_action_controller = ActionController.new(e)
	new_action_controller.name = "ActionController"
	new_action_controller.world = self.world
	new_action_controller.parent = self
	return new_action_controller

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
	# actions
	new_enemy.data.actions.controller = _init_action_controller(new_enemy)

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
	if time_controller.cycling && self.world:
		# check enemies for defeat conditions
		_check_enemies(enemy_array)
		
		# get action for each enemy
		for e in enemies:
			e.data.actions.controller.get_action()
			e.data.actions.controller.evaluate_action()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process enemy cycle
	_process_cycle(self.enemies)
