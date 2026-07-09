extends EntityController

# scripts
var party_controller_script = preload("res://src/controllers/entities/player/party_controller.gd")

# components
var init_class: Player.PlayerClass = Player.PlayerClass.BASE

var party_controller: Controller

var exp_step: int
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
		check_resource_surplus(p)

	# log resource acquisition
	FileLogger.log_message(self, "Resource acquired.")
	
	# flag action as complete
	p.data.actions.action.data.done = true

	# update world ref 
	if self.world.data.terrain.data.resources.count == 0:
		self.world.data.terrain.data.map_complete = true
	else:
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
func check_resource_surplus(p: Player):
	# get # of times regen amt fits into missing health
	var regen_amt: float = p.data.stats.base_health * float(p.data.stats.regen_rate)
	var n_regen = snapped((p.data.stats.max_health - p.data.stats.health) / regen_amt, 0.01)
	# check if food surplus,
	if p.data.resources.food > 0 && (
			p.data.stats.health < p.data.stats.max_health
	):
		if p.data.resources.food > 0:
			# if regen times is more than surplus allows,
			if n_regen > p.data.resources.food:
				# get the difference
				var difference: float = snapped(p.data.resources.food - float(n_regen), 0.01)
				n_regen += difference
			# apply regen times to amount
			regen_amt *= n_regen
			var new_health = snapped(
				clamp(
					p.data.stats.health + float(regen_amt), 0, p.data.stats.max_health),
					0.01)
			p.data.stats.health = new_health
			# reduce resource surplus by n_regen if surplus > 0
			# else reduce food by n_regen
			p.data.resources.food = (
				snapped(p.data.resources.food - n_regen, 0.01) if (p.data.resources.food > 0
				) else (p.data.resources.food)
		)
		

## process stat rewards considering the cycle's encounter
func _process_rewards(p: Player, encounter: Dictionary):
	# reward player exp
	var map_count = self.world.data.terrain.data.map_count
	var enemy_exp = encounter.n_enemies * map_count
	
	p.data.stats.exp += self.exp_step + enemy_exp

	FileLogger.log_message(self,
		str(self.exp_step + enemy_exp) + " exp rewarded."
	)

	# check for item rewards
	var r = randf()
	var n = 0.10 # 5% for enemy to drop item
	if r <= n && p.data.inventory.bags.size() < 10:
		var r_slots = ["weapon", "head", "chest", "legs", "feet"]
		var r_item = r_slots.pick_random()
		var new_item = null
		match r_item:
			"weapon":
				var weapon_c = Weapon.WeaponClass.values().pick_random()
				var new_weapon = Weapon.WeaponClasses[weapon_c].new()
				new_item = new_weapon
			"head":
				var new_armor = Armor.armor_slots[0].new()
				new_item = new_armor
			"chest":
				var new_armor = Armor.armor_slots[1].new()
				new_item = new_armor
			"legs":
				var new_armor = Armor.armor_slots[2].new()
				new_item = new_armor
			"feet":
				var new_armor = Armor.armor_slots[3].new()
				new_item = new_armor
		
		# check if player has item already equipped
		var equipped = p.data.inventory.controller.get_equipped(r_item)
		var equipment_string = new_item.get_script().get_global_name()
		# if not,
		if equipped == null:
			# equip it
			p.data.inventory.controller.equip_item(new_item)
			FileLogger.log_message(self,
				p.name + " has equipped a new " +
				equipment_string)
		# if so,
		else:
			# add to bag
			p.data.inventory.controller.add_item(new_item)
			FileLogger.log_message(self,
				"A new " + equipment_string + " has been added to bags")

	# check if level_up
	var level_up = false
	if p.data.stats.exp >= self.exp_cap:
		# calculate player stats
		p.data.stats = _calculate_stats(p)
		level_up = true
	
		# update exp_cap reference
		p.data.stats.exp_cap = self.exp_cap
		
		var msg = (
			"src_lvl: " + str(p.data.stats.level) + " | " +
			"src_exp: " + str(p.data.stats.exp) + " | " +
			"exp_rate: " + str(self.exp_step) + " | " +
			"exp_cap: " + str(self.exp_cap)
		)
		FileLogger.log_message(self, msg)

	# log if level up
	if level_up:
		# reset player health to max if level up
		p.data.stats.health = p.data.stats.max_health
		FileLogger.log_message(self, p.name + " is now level " + str(p.data.stats.level))
	
	# if no level up,
	else:
		# check surplus
		check_resource_surplus(p)

	
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


## initializes the party system controller
func _init_party_controller() -> Controller:
	var new_party_controller = party_controller_script.new()
	new_party_controller.world = self.world
	new_party_controller.parent = self
	self.party_controller = new_party_controller
	return new_party_controller


## initializes a new player entity
func _init_player_entity():
	# create new player scene of class
	var new_player_script = Player.new()
	var new_player = new_player_script.init_scene()
	
	# meta
	new_player.data.uid = self.world.data.controller.uid_ref
	self.world.data.controller.uid_ref += 1
	new_player.name = "player_" + str(new_player.data.uid)
	new_player.data.world = self.world
	new_player.data.controller = self
	
	# class
	var p_class = self.init_class
	new_player.Class = p_class
	new_player.data.class = new_player.Class
	new_player.data.class_v = new_player.get_player_class_string()
	# spin up base class script to get base class data
	var base_class_obj: Resource = new_player_script.PlayerClasses[0].new()
	# set data structure
	new_player.data.stats = base_class_obj.stats
	new_player.data.actions.abilities = base_class_obj.class_abilities
	# TODO: get user-defined attribute spread
	# for now, manually set spread
	var attributes: Array = ["stamina", "strength", "perception"]
	var attr_spread: Array = [1, 1, 1]
	var i: int = 0
	for a in attributes:
		var n = attr_spread[i]
		new_player.data.stats[a] += n
		i += 1
	# spin up class script to get class data/abilities
	if p_class != Player.PlayerClass.BASE:
		var class_obj: Resource = new_player_script.PlayerClasses[p_class].new()
		var abilities: Array = new_player.data.actions.abilities
		for a in class_obj.class_abilities:
			abilities.push_front(a)
		# sort abilities by cooldown
		abilities.sort_custom(
			func(a, b): return a.new().data.cooldown > b.new().data.cooldown)
		new_player.data.actions.abilities = abilities

	# stats
	var new_stats = _calculate_stats(new_player)
	new_player.data.stats.merge(new_stats)
	
	# actions
	new_player.data.actions.controller = _init_action_controller(new_player)

	# inventory
	var new_inventory_controller = InventoryController.new(new_player)
	new_player.data.inventory.controller = new_inventory_controller

	# equipment
	var new_weapon = UnarmedWeapon.new()
	# var new_weapon = Weapon.WeaponClasses.values().pick_random().new()
	new_player.data.inventory.equipped.weapon = new_weapon
	new_player.data.inventory.equipped.weapon = new_weapon
	
	# initialize skills
	_progress_skill(new_player, "ARMOR")
	_progress_skill(new_player, new_weapon.get_weapon_class_string())
	
	self.world.data.player = new_player
	
	# add player to tree
	self.add_child(new_player)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# TODO: account for multiple players
	_init_party_controller()

	# initialize the player entity as scene
	_init_player_entity()
	
	FileLogger.log_message(self, "::INITIALIZED::")


# Player Processing

## checks player defeat conditions and deletes entity object if met
func _check_player(p: Player):
	# if player health is 0 or below and last_stand remaining,
	if p.data.stats.health <= 0:
		if p.data.actions.last_stand:
			if p.data.resources.food > 0:
				p.data.resources.food = 0
				p.data.stats.health = p.data.stats.max_health
				p.data.actions.last_stand = false
				FileLogger.log_message(self, p.name +
					" is taking a last stand!")
			
			# no food for last stand, player is dead
			else:
				# if player isn't already queued for deletion,
				if !p.is_queued_for_deletion():
					p.data.actions.metrics["highest_map"] = self.world.data.terrain.data.map_count
					FileLogger.log_message(self,
						str(p.data),
						"INFO",
						FileLogger.Outputs.find_key(
							FileLogger.Outputs.GAME_LOG_PATH))

					# queue for deletion
					p.queue_free()

		# no last stand remaining, 
		else:
			# if player isn't already queued for deletion,
			if !p.is_queued_for_deletion():
				p.data.actions.metrics["highest_map"] = self.world.data.terrain.data.map_count
				FileLogger.log_message(self,
					str(p.data),
					"INFO",
					FileLogger.Outputs.find_key(
						FileLogger.Outputs.GAME_LOG_PATH))

				# queue for deletion
				p.queue_free()


# checks if an active encounter is complete and rewards player if so
func check_encounter(p: Player) -> bool:
	# get encounter controller,
	var world_controller = self.world.data.controller
	var encounter_controller = world_controller.terrain_controller.encounter_controller
	# Aif encounter controller is not processing an encounter,
	var result = false
	if !encounter_controller.encountering:
		# get player rewards with active encounter
		var current_encounter = encounter_controller.encounter
		_process_rewards(p, current_encounter)
		# move active encounter to done and set active null
		p.data.encounters.done += 1
		p.data.encounters.active = false
		result = true
	
	# return result flag
	return result


## determines and processes player logic for a time cycle
func _process_cycle(p: Player):
	# if time cycling,
	var time_controller = world.data.controller.time_controller
	if time_controller:
		if time_controller.cycling:
			# check player health,
			_check_player(p)
			
			# if terrain map complete,
			if self.world.data.terrain.data.map_complete:
				# reset player health
				# and wait for new map to be initialized
				p.data.stats.health = p.data.stats.max_health
				return
			
			# get player action for cycle
			if is_instance_valid(p):
				if not p.is_queued_for_deletion():
					p.data.actions.controller.get_action()


func _process(_delta: float) -> void:
	# if party lead is valid,
	if is_instance_valid(self.world.data.player):
		# process player cycles
		_process_cycle(self.world.data.player)
