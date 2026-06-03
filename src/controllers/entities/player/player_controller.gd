extends EntityController

# references
var FileLogger
var player_scene = preload("res://src/entities/player/player.tscn")
var player: Player
# components
var pid_ref = 0
var cycle_complete = false

var player_speed = 1

var exp_step: int = 1
var exp_rate: int
var exp_cap: int

var regen_rate: float = 0.5


# Player Actions

## returns an array of world resources
func _get_resources() -> Array:
	var array = []
	var tile_map = self.world.data.terrain.tile_map
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			var t = tile_map[x][y]
			if t.data.resources.food:
				array.append(t)
	return array

# Player Stats

## process stat rewards considering the cycle's encounter
func _process_rewards(encounter: Dictionary):
	# reward player exp based on number of enemies killed
	# var map_count = self.world.data.terrain.map_count
	self.player.data.stats.exp += (
		self.exp_rate * (encounter.n_enemies)
	)
	FileLogger.log_message(self ,
		str(self.exp_rate * (encounter.n_enemies)) + " exp rewarded."
	)
	
	# check if level_up
	var level_up = false
	if self.player.data.stats.exp >= self.exp_cap:
		# calculate player stats
		self.player.data.stats = _calculate_stats(self.player.data.stats, false)
		level_up = true
	
		# update exp_cap reference
		self.player.data.stats.exp_cap = self.exp_cap
		
		FileLogger.log_message(self , "src_lvl: " + str(self.player.data.stats.level))
		FileLogger.log_message(self , "src_exp: " + str(self.player.data.stats.exp))
		FileLogger.log_message(self , "exp_rate: " + str(self.exp_rate))
		FileLogger.log_message(self , "exp_cap: " + str(self.exp_cap))


	# log if level up
	if level_up:
		# reset player health to max if level up
		self.player.data.stats.health = self.player.data.stats.max_health
		FileLogger.log_message(self , self.player.name + " is now level " + str(self.player.data.stats.level))

## calculates player stats and returns stats dict
func _calculate_stats(stats: Dictionary, init: bool = true) -> Dictionary:
	# if init call,
	if init:
		stats.level = 1
		self.exp_step = (stats.level)
		self.exp_rate = floor(self.exp_step) * (PI)
		self.exp_cap = floor(self.exp_step) * (self.exp_rate) * (PI)
		stats.exp_cap = self.exp_cap
		# increment attributes
		stats.max_health += stats.resilience * 10
		stats.attack += stats.strength
		stats.health = stats.max_health
	# if level increment call,
	else:
		# increment level
		stats.level += 1
		## calculate player experience variables
		self.exp_step = (stats.level)
		self.exp_rate = floor(self.exp_step) * (PI)
		self.exp_cap = floor(self.exp_step) * (self.exp_rate) * (PI)
		# reset experience value
		stats.exp = 0
		# increment attributes
		stats.resilience += 1
		stats.strength += 1
		stats.max_health += stats.resilience * 10
		stats.attack += stats.strength

	return stats

# Player Initialization

## initializes a new player entity
func _init_player_entity():
	var world_controller = self.world.data.controller
	var new_player = self.player_scene.instantiate()
	# metadata
	new_player.data.uid = world_controller.uid_ref
	new_player.data.pid = self.pid_ref
	new_player.name = "player_" + str(new_player.data.pid)
	new_player.world = self.world
	new_player.data.controller = self
	# stats
	new_player.data.stats = _calculate_stats(new_player.data.stats)

	self.player = new_player
	self.add_child(new_player)
	
	# update uid ref
	world_controller.uid_ref += 1
	self.pid_ref += 1

	return self.player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"
	## TODO: account for multiple players
	# initialize the player entity as scene
	var new_player = _init_player_entity()
	if new_player:
		FileLogger.log_message(self , "Player initialized.")
		self.world.data.player = self.player

# Player Processing

## checks player defeat conditions and deletes entity object if met
func _check_player(p: Player):
	# if player health is 0 or below
	if p.data.stats.health <= 0:
		# if enemy isn't already queued for deletion,
		if !p.is_queued_for_deletion():
			# queue for deletion
			p.queue_free()

## determines and processes player logic for a time cycle
func _process_cycle():
	# if time cycling,
	var time_controller = world.data.controller.time_controller
	if time_controller.cycling && self.player:
		# check player health,
		_check_player(self.player)

		# if resources exist and player encounter inactive,
		if self.world.data.terrain.resources.count > 0 && (
			! self.player.data.encounters.active
		):
			# get closest resource tile
			var resources = _get_resources()
			var n_resources = resources
			# sort resources by distance to player
			n_resources.sort_custom(func(a, b): return (
					self.player.global_position.distance_squared_to(a.global_position) <
					self.player.global_position.distance_squared_to(b.global_position)))
			var n_resource = n_resources.front()
			# move player to tile
			self.player.global_position = lerp(
				self.player.global_position, n_resource.global_position,
				1
			)
			# update grid_idx
			var world_controller = self.world.data.controller
			var grid_scale = world_controller.terrain_controller.grid_scale
			self.player.data.grid_idx = world_controller.utils.world_to_grid(
				self.player.global_position, grid_scale
			)
			
			# interact with tile
			# get current tile
			var current_tile = world_controller.utils.get_object_by_grid(
				self.player.data.grid_idx, self.world.data.terrain.tile_map)
			# check if encounter
			var is_encounter = current_tile.data.encounters["spawn"].call(self.player)
			# if encounter spawned,
			if is_encounter:
				# set player to encountering
				self.player.data.encounters.active = is_encounter
			# no encounter spawned,
			else:
				# take resources from tile
				current_tile.data.resources.food = false
				# update world ref 
				self.world.data.terrain.resources.count -= 1
				# give resources to player
				self.player.data.resources.food += 1
				# increase player health by regen_rate if resource
				var regen = self.player.data.stats.max_health * (self.regen_rate)
				var new_health = clamp(self.player.data.stats.health + regen, 0, self.player.data.stats.max_health)
				self.player.data.stats.health = new_health
				# log resource acquisition
				FileLogger.log_message(self , "Resource acquired.")

		# if resources exist and player encounter active,
		elif self.world.data.terrain.resources.count > 0 && (
			self.player.data.encounters.active
		):
			# get encounter controller,
			var world_controller = self.world.data.controller
			var encounter_controller = world_controller.terrain_controller.encounter_controller
			# check if encounter done,
			if !encounter_controller.encountering:
				# get player rewards with active encounter
				var current_encounter = encounter_controller.encounter
				_process_rewards(current_encounter)
				# move active encounter to done and set active null
				self.player.data.encounters.done.append(current_encounter)
				self.player.data.encounters.active = false
				# get current tile
				var current_tile = world_controller.utils.get_object_by_grid(
					self.player.data.grid_idx, self.world.data.terrain.tile_map)
				# take resources from tile
				current_tile.data.resources.food = false
				# update world ref 
				self.world.data.terrain.resources.count -= 1
				# give resources to player
				self.player.data.resources.food += 1
				# increase player health by regen_rate if resource
				var regen = self.player.data.stats.max_health * (self.regen_rate)
				var new_health = clamp(self.player.data.stats.health + regen, 0, self.player.data.stats.max_health)
				self.player.data.stats.health = new_health
				# log resource acquisition
				FileLogger.log_message(self , "Resource acquired.")

		# if no resources in world,
		elif self.world.data.terrain.resources.count == 0:
			# flag map complete on terrain
			self.world.data.terrain.map_complete = true
			# reset player health on new map
			self.player.data.stats.health = self.player.data.stats.max_health

func _process(delta: float) -> void:
	# process player cycle
	_process_cycle()