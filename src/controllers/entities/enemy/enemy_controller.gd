extends EntityController

# components
var enemies: Array = []

# Enemy Initialization

## spawns n enemy entities and returns them in an erray
func spawn_enemies(n: int = 1) -> Array:
	var new_enemies = []
	for e in range(n):
		var new_enemy = _init_enemy_entity()
		new_enemy.data.stats = _calculate_stats(new_enemy)
		var new_weapon = UnarmedWeapon.new()
		new_enemy.data.inventory.equipped.weapon = new_weapon
		new_enemies.append(new_enemy)
		# initialize armor skill
		_progress_skill(new_enemy, "ARMOR")
		# initialize weapon skill
		_progress_skill(
			new_enemy, new_enemy.data.inventory.equipped.weapon.get_weapon_class_string())
			
	self.enemies = new_enemies
	return new_enemies

## initializes a new action controller for the given player entity
func _init_action_controller(e: Enemy) -> ActionController:
	# initialize the controller
	var new_action_controller = ActionController.new(e)
	new_action_controller.name = "ActionController"
	new_action_controller.world = self.world
	new_action_controller.parent = self
	new_action_controller.Utils = self.Utils
	new_action_controller.FileLogger = self.FileLogger
	return new_action_controller

## initializes enemy entity
func _init_enemy_entity():
	var world_controller = self.parent
	var new_enemy = Enemy.new().init_scene()
	# metadata
	new_enemy.data.uid = world_controller.uid_ref
	new_enemy.name = "enemy_" + str(new_enemy.data.uid)
	new_enemy.data.world = self.world
	new_enemy.data.controller = self
	# actions
	new_enemy.data.actions.controller = _init_action_controller(new_enemy)
	# inventory
	var new_inventory_controller = InventoryController.new(new_enemy)
	new_enemy.data.inventory.controller = new_inventory_controller

	add_child(new_enemy)
	
	# update uid ref
	world_controller.uid_ref += 1

	return new_enemy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

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
	if time_controller:
		if time_controller.cycling && self.world:
			# check enemies for defeat conditions
			_check_enemies(enemy_array)
			# process each enemy's action
			for e in enemies:
				if not is_instance_valid(e):
					continue
				# process their action immediately
				e.data.actions.controller.get_action()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# process enemy cycle
	_process_cycle(self.enemies)
