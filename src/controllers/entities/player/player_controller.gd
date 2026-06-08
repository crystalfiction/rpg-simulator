extends EntityController

# references
var player: Player
# components
var exp_step: int = 1
var exp_rate: int
var exp_cap: int


# Player Action Helpers

## finds the nearest resource tile to player and returns it
func find_nearest_resource(p: Player, w: World) -> Tile:
	# get all resource tiles
	var utils = w.data.controller.utils
	var tile_map = w.data.terrain.tile_map
	var resources = utils.get_resources(tile_map)
	var n_resources = resources
	# sort resources by distance to player
	n_resources.sort_custom(func(a, b): return (
			p.global_position.distance_squared_to(a.global_position) <
			p.global_position.distance_squared_to(b.global_position)))
	# return nearest resource
	var n_resource = n_resources.front()
	return n_resource

# Player Actions

## interacts with the current tile depending on resources, encounters
func interact_with_tile(p: Player, current_tile: Tile):
	# take resources from tile
	current_tile.data.resources.food = false
	# update world ref 
	self.world.data.terrain.resources.count -= 1
	# give resources to player
	p.data.resources.food += 1
	
	# if player health already max,
	if p.data.stats.health == p.data.stats.max_health:
		# add to food surplus
		p.data.resources.surplus += 1
	# if player health below max,
	else:
		# increase by regen_rate
		var regen = p.data.stats.max_health * (p.data.stats.regen_rate)
		var new_health = clamp(p.data.stats.health + regen, 0, p.data.stats.max_health)
		p.data.stats.health = new_health

	# log resource acquisition
	FileLogger.log_message(self , "Resource acquired.")
	# flag action as complete
	p.data.actions.action.done = true

## moves the passed player to the passed tile and updates player grid_idx
func move_to_tile(p: Player, t: Tile):
	# move player to tile
	p.global_position = lerp(
		p.global_position, t.global_position,
		1
	)
	# update grid_idx
	var world_controller = self.world.data.controller
	var grid_scale = world_controller.terrain_controller.grid_scale
	p.data.grid_idx = world_controller.utils.world_to_grid(
		p.global_position, grid_scale
	)

## moves the passed player one tile towards the passed tile,
## or to the passed tile if only one tile distance
func move_towards_tile(p: Player, t: Tile) -> bool:
	var utils = self.world.data.controller.utils
	# get direction to tile
	var p_idx = p.data.grid_idx as Vector2
	var t_idx = t.data.grid_idx as Vector2
	var direction = (t_idx - p_idx).normalized().snapped(Vector2(1, 1))
	# get object 1 tile away in direction towards t tile from player p
	var target = Vector2i(p_idx + direction)
	var target_obj = utils.get_object_by_grid(
		target, self.world.data.terrain.tile_map)
	# move to target
	move_to_tile(p, target_obj)

	# check if player is at target and return result
	if p.data.grid_idx == t.data.grid_idx:
		return true
	else:
		return false

# Player Stats

## process stat rewards considering the cycle's encounter
func _process_rewards(encounter: Dictionary):
	# reward player exp 
	self.player.data.stats.exp += self.exp_step

	FileLogger.log_message(self ,
		str(self.exp_step * (encounter.n_enemies)) + " exp rewarded."
	)
	
	# check if level_up
	var level_up = false
	if self.player.data.stats.exp >= self.exp_cap:
		# calculate player stats
		self.player.data.stats = _calculate_stats(self.player)
		level_up = true
	
		# update exp_cap reference
		self.player.data.stats.exp_cap = self.exp_cap
		
		var msg = (
			"src_lvl: " + str(self.player.data.stats.level) + " | " +
			"src_exp: " + str(self.player.data.stats.exp) + " | " +
			"exp_rate: " + str(self.exp_step) + " | " +
			"exp_cap: " + str(self.exp_cap)
		)
		FileLogger.log_message(self , msg)

	# log if level up
	if level_up:
		# reset player health to max if level up
		self.player.data.stats.health = self.player.data.stats.max_health
		FileLogger.log_message(self , self.player.name + " is now level " + str(self.player.data.stats.level))

# Player Initialization

## initializes a new action controller for the given player entity
func _init_action_controller(p: Player) -> ActionController:
	# initialize the controller
	var new_action_controller = ActionController.new(p)
	new_action_controller.name = "ActionController"
	new_action_controller.world = self.world
	new_action_controller.parent = self
	new_action_controller.FileLogger = self.FileLogger
	return new_action_controller

## initializes a new player entity
func _init_player_entity():
	var world_controller = self.world.data.controller
	# create new player scene
	var new_player = BaseClass.new().init_scene()
	# metadata
	new_player.data.uid = world_controller.uid_ref
	new_player.data.world = self.world
	new_player.data.controller = self
	# stats
	new_player.data.stats = _calculate_stats(new_player)
	# actions
	new_player.data.actions.controller = _init_action_controller(new_player)
	
	# add player
	self.player = new_player
	self.add_child(new_player)
	
	# update uid ref
	world_controller.uid_ref += 1

	# return player
	return self.player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"

	# TODO: account for multiple players
	# initialize the player entity as scene
	_init_player_entity()

	# TODO: give player weapon
	var new_weapon = Sword.new()
	self.player.data.inventory.equipped.weapon = new_weapon

	# update player entity reference
	self.world.data.player = self.player
	
	FileLogger.log_message(self , "Player initialized.")

# Player Processing

## checks player defeat conditions and deletes entity object if met
func _check_player(p: Player):
	# if player health is 0 or below
	if p.data.stats.health <= 0:
		# if enemy isn't already queued for deletion,
		if !p.is_queued_for_deletion():
			FileLogger.log_message(self ,
				"Final stats: " + str(self.world.data.player.data.stats)
			)
			# queue for deletion
			p.queue_free()

# checks if an active encounter is complete and rewards player if so
func check_encounter(p: Player) -> bool:
	# get encounter controller,
	var world_controller = self.world.data.controller
	var encounter_controller = world_controller.terrain_controller.encounter_controller
	# if encounter controller is not processing an encounter,
	var result = false
	if !encounter_controller.encountering:
		# get player rewards with active encounter
		var current_encounter = encounter_controller.encounter
		_process_rewards(current_encounter)
		# move active encounter to done and set active null
		p.data.encounters.done.append(current_encounter)
		p.data.encounters.active = false
		result = true
	
	# return result flag
	return result

## determines and processes player logic for a time cycle
func _process_cycle(p: Player):
	var time_controller = world.data.controller.time_controller
	# if time cycling,
	# and if player valid
	if time_controller.cycling:
		# check player health,
		_check_player(p)

		# get player action for cycle
		p.data.actions.controller.get_action()

		# if terrain map complete,
		if self.world.data.terrain.map_complete:
			# reset player health
			# and wait for new map to be initialized
			p.data.stats.health = p.data.stats.max_health

func _process(delta: float) -> void:
	# if player is valid,
	if is_instance_valid(self.player):
		# process player cycle
		_process_cycle(self.player)