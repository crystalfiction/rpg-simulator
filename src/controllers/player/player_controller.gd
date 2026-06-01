extends Controller

# references
var player_scene = preload("res://src/entities/player/player.tscn")
var actions_controller_script = preload("res://src/controllers/player/actions_controller.gd")

var actions_controller: Controller

var player: Player

# components
var pid_ref = 0
var cycle_complete = false

var player_speed = 1

var exp_step: int = 1
var exp_rate: int = floor(
	(self.exp_step) + (PI * 10))
var exp_cap: int = floor(
	(self.exp_step) * (self.exp_rate) * (PI * 10))


## TODO: process rewards considering the cycle results, resources/encounters
func _process_encounter_rewards(encounter: Dictionary):
	# reward player exp based on number of enemies killed
	self.player.data.stats.exp += (
		self.exp_rate * (encounter.n_enemies)
	)
	
	# check if level_up
	var level_up = false
	if self.player.data.stats.exp >= self.exp_cap:
		## calculate player experience variables
		self.exp_step = (self.player.data.stats.level)
		self.exp_rate = floor((self.exp_step) + (PI * 10))
		self.exp_cap = floor((self.exp_step) * (self.exp_rate) * (PI * 10))
		# reset experience value
		self.player.data.stats.exp = 0
		# increment level
		self.player.data.stats.level += 1
		level_up = true
	
	# update exp_cap reference
	self.player.data.stats.exp_cap = self.exp_cap
	
	# reset player health to max post-encounter
	self.player.data.stats.health = self.player.data.stats.max_health
	
	print(
		"src_lvl: " + str(self.player.data.stats.level) + " | ",
		"src_exp: " + str(self.player.data.stats.exp) + " | ",
		"exp_rate: " + str(self.exp_rate) + " | ",
		"exp_cap: " + str(self.exp_cap),
	)
	
	# log if level up
	if level_up:
		print(self.player.name + " is now level " + str(self.player.data.stats.level))


# returns an array of world resources
func _get_resources() -> Array:
	var array = []
	var tile_map = self.world.data.terrain.tile_map
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			var t = tile_map[x][y]
			if t.data.resources.food:
				array.append(t)
	return array

# evaluates combat during an encounter
func evaluate_combat(p: Player, e: Enemy):
	var p_health = p.data.stats.health
	var e_attack = e.data.stats.attack
	var e_hit = e.data.stats.hit_chance
	# evaluate if enemy attack is hit
	var r = randf_range(0, 1)
	# if random number r is below hit threshold
	if r <= e_hit:
		# attack is a hit
		p_health -= e_attack
		p.data.stats.health = p_health
	# if miss,
	else:
		# attack is 0 this turn
		e_attack = 0

	# log results
	print(
		e.name + " hits " + p.name + " for " +
		str(e_attack) + " dmg.", "\n",
		p.name + " health: " + str(p_health)
	)

	# check player state after combat
	_check_player(self.player)


## initializes a new actions controller for a given player
func _init_actions_controller(p: Player):
	# create new action controller for p
	var new_actions_controller = self.actions_controller_script.new()
	new_actions_controller.name = "ActionsController"
	new_actions_controller.parent = self
	new_actions_controller.world = self.world
	new_actions_controller.player = p
	# add ref to player.data.actions.controller
	p.data.actions.controller = new_actions_controller
	# add as child to player
	p.add_child(new_actions_controller)
	
	# validate result
	var result = p
	if !result:
		result = ERR_INVALID_PARAMETER
	return result


# initializes player entity
func _init_player_entity():
	var world_controller = self.world.data.controller
	var new_player = self.player_scene.instantiate()
	# metadata
	new_player.data.uid = world_controller.uid_ref
	new_player.data.pid = self.pid_ref
	new_player.name = "player_" + str(new_player.data.pid)
	new_player.data.world = self.world
	new_player.data.controller = self
	# stats
	new_player.data.stats.level = 1
	new_player.data.stats.exp = self.exp_rate
	new_player.data.stats.exp_cap = self.exp_cap
	new_player.data.stats.health = new_player.data.stats.max_health

	self.player = new_player
	self.add_child(new_player)
	
	# update uid ref
	world_controller.uid_ref += 1
	self.pid_ref += 1

	return self.player


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## TODO: account for multiple players
	# initialize the player entity as scene
	var new_player = _init_player_entity()
	if new_player:
		# initialize the actions controller on player
		new_player = _init_actions_controller(new_player)
		print("Player initialized.")
		self.world.data.player = self.player


func _check_player(p: Player):
	# if enemy health is 0 or below
	if p.data.stats.health <= 0:
		# if enemy isn't already queued for deletion,
		if !p.is_queued_for_deletion():
			# queue for deletion
			p.queue_free()


# determines and processes player logic for a single time cycle
func _process_cycle():
	# only process if time cycling,
	var time_controller = world.data.controller.time_controller
	if time_controller.cycling && self.world:
		# check player health,
		_check_player(self.player)

		# if resources in world,
		if self.world.data.terrain.resources.count > 0 && (
			! self.player.data.encounters.active
		):
			## get closest world resource tile
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
			
			## interact with tile
			# get current tile
			var current_tile = world_controller.utils.get_object_by_grid(
				self.player.data.grid_idx, self.world.data.terrain.tile_map)
			# check if encounter
			var encounter = current_tile.data.encounters["spawn"].call(self.player)
			# if encounter spawned,
			if !encounter.enemies.is_empty():
				# set player to encountering
				self.player.data.encounters.active = encounter
			else:
				# take resources from tile
				current_tile.data.resources.food = false
				# update world ref 
				self.world.data.terrain.resources.count -= 1
				# give resources to player
				self.player.data.resources.food += 1
				print("Resource acquired.")

		# if player encountering,
		elif self.world.data.terrain.resources.count > 0 && (
			self.player.data.encounters.active
		):
			var world_controller = self.world.data.controller
			# get encounter controller,
			var encounter_controller = world_controller.terrain_controller.encounter_controller
			# check if encounter done,
			if !encounter_controller.encountering:
				# set player to done encountering if so
				self.player.data.encounters.done.append(self.player.data.encounters.active)
				self.player.data.encounters.active = false
				# get player rewards
				_process_encounter_rewards(self.player.data.encounters.done.back())
				# get current tile
				var current_tile = world_controller.utils.get_object_by_grid(
					self.player.data.grid_idx, self.world.data.terrain.tile_map)
				# take resources from tile
				current_tile.data.resources.food = false
				# update world ref 
				self.world.data.terrain.resources.count -= 1
				# give resources to player
				self.player.data.resources.food += 1
				print("Resource acquired.")

		# if no resources in world,
		elif self.world.data.terrain.resources.count == 0:
			# flag map complete on terrain
			self.world.data.terrain.map_complete = true


func _process(delta: float) -> void:
	# process cycle
	_process_cycle()