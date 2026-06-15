extends EntityController

# components
var player: Player

var exp_step: int = 1
var exp_rate: int
var exp_cap: int


# Player Action Helpers

## finds the nearest resource tile to player and returns it
func find_nearest_resource(p: Player, w: World) -> Tile:
	# get all resource tiles
	var tile_map = w.data.terrain.data.tile_map
	var resources = self.Utils.get_resources(tile_map)
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
	
	# give resources to player
	p.data.resources.food += 1
	p.data.resources.total += 1
	
	# if player health not at max,
	if p.data.stats.health < p.data.stats.max_health:
		_check_resource_surplus(p)

	# log resource acquisition
	FileLogger.log_message(self , "Resource acquired.")
	
	# flag action as complete
	p.data.actions.action.data.done = true

	# update world ref 
	self.world.data.terrain.data.resources.count -= 1

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
	p.data.grid_idx = self.Utils.world_to_grid(
		p.global_position, grid_scale
	)

## moves the passed player one tile towards the passed tile,
## or to the passed tile if only one tile distance
func move_towards_tile(p: Player, t: Tile) -> bool:
	# get direction to tile
	var p_idx = p.data.grid_idx as Vector2
	var t_idx = t.data.grid_idx as Vector2
	var direction = (t_idx - p_idx).normalized().snapped(Vector2(1, 1))
	# get object 1 tile away in direction towards t tile from player p
	var target = Vector2i(p_idx + direction)
	var target_obj = self.Utils.get_object_by_grid(
		target, self.world.data.terrain.data.tile_map)
	# move to target
	move_to_tile(p, target_obj)

	# check if player is at target and return result
	if p.data.grid_idx == t.data.grid_idx:
		return true
	else:
		return false


# Player Stats

## checks whether player has surplus resources
## and evaluates rewards accordingly
func _check_resource_surplus(p: Player):
	# get # of times regen amt fits into missing health
	var regen_amt = p.data.stats.max_health * (p.data.stats.regen_rate)
	var n_regen = ceil((p.data.stats.max_health - p.data.stats.health) / regen_amt)
	# check if food surplus,
	if p.data.resources.food > 0 && (
			p.data.stats.health < p.data.stats.max_health
	):
		if p.data.resources.food > 0:
			# if regen times is more than surplus allows,
			if n_regen > player.data.resources.food:
				# get the difference
				var difference = player.data.resources.food - n_regen
				n_regen += difference
			# apply regen times to amount
			regen_amt *= n_regen
			var new_health = clamp(
				p.data.stats.health + regen_amt, 0, p.data.stats.max_health)
			p.data.stats.health = new_health
			# reduce resource surplus by n_regen if surplus > 0
			# else reduce food by n_regen
			p.data.resources.food = (
				(p.data.resources.food - n_regen) if (p.data.resources.food > 0
				) else (p.data.resources.food)
		)
		

## process stat rewards considering the cycle's encounter
func _process_rewards(encounter: Dictionary):
	# reward player exp
	var map_count = self.world.data.terrain.data.map_count
	var enemy_exp = encounter.n_enemies * map_count
	self.player.data.stats.exp += self.exp_step + enemy_exp

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
	else:
		_check_resource_surplus(self.player)

	
# Player Initialization

## initializes a new action controller for the given player entity
func _init_action_controller(p: Player) -> ActionController:
	# initialize the controller
	var new_action_controller = ActionController.new(p)
	new_action_controller.name = "ActionController"
	new_action_controller.world = self.world
	new_action_controller.parent = self
	new_action_controller.Utils = self.Utils
	new_action_controller.FileLogger = self.FileLogger
	return new_action_controller

## initializes a new player entity
func _init_player_entity():
	# create new player scene of class
	var new_player_script = Player.new()
	var new_player = new_player_script.init_scene()
	
	# metadata
	new_player.data.uid = self.world.data.controller.uid_ref
	new_player.data.world = self.world
	new_player.data.controller = self
	
	# class
	var p_class = Player.PlayerClass.WANDERER
	new_player.Class = p_class
	# spin up class script to get init class stats and abilities
	var class_obj = new_player_script.PlayerClasses[p_class].new()
	new_player.data.stats = class_obj.stats
	new_player.data.actions.abilities.append_array(class_obj.class_abilities)
	
	# stats
	new_player.data.stats = _calculate_stats(new_player)
	
	# actions
	new_player.data.actions.controller = _init_action_controller(new_player)

	# start player unarmed
	var new_weapon = UnarmedWeapon.new()
	new_player.data.inventory.equipped.weapon = new_weapon
	# TODO: start player armored according to class
	# new_player.data.inventory.equipped.head = 
	# new_player.data.inventory.equipped.chest = 
	# new_player.data.inventory.equipped.legs = 
	# new_player.data.inventory.equipped.feet = 

	# update uid ref
	self.world.data.controller.uid_ref += 1
	
	# update player entity reference
	self.player = new_player
	self.world.data.player = self.player
	
	# add player to tree
	self.add_child(new_player)

	# return player
	return new_player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# TODO: account for multiple players
	# initialize the player entity as scene
	_init_player_entity()
	
	# progress player skill before processing
	EntityController.new()._progress_skill(
		self.player,
		self.player.data.inventory.equipped.weapon.get_weapon_class_string())
	
	FileLogger.log_message(self , "Player initialized.")


# Player Processing

## checks player defeat conditions and deletes entity object if met
func _check_player(p: Player):
	# if player health is 0 or below
	if p.data.stats.health <= 0:
		# if enemy isn't already queued for deletion,
		if !p.is_queued_for_deletion():
			FileLogger.log_message(self ,
				str(self.player.data.stats)
			)
			FileLogger.log_message(self ,
				str(self.player.data.skills)
			)
			FileLogger.log_message(self ,
				str(self.player.data.resources)
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
	if time_controller:
		if time_controller.cycling:
			# if terrain map complete,
			if self.world.data.terrain.data.map_complete:
				# reset player health
				# and wait for new map to be initialized
				p.data.stats.health = p.data.stats.max_health
				return

			# check player health,
			_check_player(p)
			
			# get player action for cycle
			if not p.is_queued_for_deletion():
				p.data.actions.controller.get_action()

func _process(delta: float) -> void:
	# if player is valid,
	if is_instance_valid(self.player):
		# process player cycle
		_process_cycle(self.player)