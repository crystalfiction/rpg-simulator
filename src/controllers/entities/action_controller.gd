class_name ActionController extends Controller

# refs
var entity: Entity
var on_cooldown: Array = []


# Cooldowns

## gets the next available attack in entity abilities queue
func _get_attack() -> AttackAction:
	var new_action = null
	# if abilities array,
	if "abilities" in self.entity.data.actions:
		var abilities = self.entity.data.actions.abilities
		for a in abilities:
			var new_a = a.new()
			var exists = _check_cooldowns(new_a, self.on_cooldown)
			if not exists:
				new_action = new_a
				# return first available
				return new_action

	# if no abilities array,
	else:
		# assign basic attack
		new_action = BasicAttack.new()

	return new_action

## checks whether or not the passed action exists in any context
## (instance, type) in cooldowns array
func _check_cooldowns(action: AttackAction, cooldowns: Array) -> bool:
	var type = action.get_attack_type()
	var exists = cooldowns.filter(
		func(a): return a.get_attack_type() == type
	).size() > 0 && action not in cooldowns
	return exists

## puts an action on cooldown by adding to on_cooldown array
func _add_cooldown(action: AttackAction, cooldowns: Array):
	# going on cooldown,
	if "cooldown" in action.data:
		var exists = _check_cooldowns(action, cooldowns)
		if (
			action.data.cooldown > 0 &&
			not exists
		):
			# cooldown exists,
			# add to on_cooldown
			cooldowns.append(action)

## handles on_cooldown array
func _handle_cooldowns(cooldowns: Array) -> Array:
	# on cooldown,
	if cooldowns.size() > 0:
		for c in cooldowns:
			# reduce each cycle until == 0
			if c.data.cooldown > 0:
				c.data.cooldown -= 1
			
			# if cooldown 0,
			elif c.data.cooldown == 0:
				# remove from on_cooldown
				var idx = cooldowns.find(c)
				cooldowns.pop_at(idx)
			
	return cooldowns


# Action Processing

## gets a new action for parent entity,
## to be evaluated over one or more cycles by evaluate_action
func get_action():
	# handle action cooldowns every cycle
	self.on_cooldown = _handle_cooldowns(self.on_cooldown)

	# if Player entity,
	if self.entity is Player:
		# if resources exist and player not in encounter,
		if "count" in self.world.data.terrain.data.resources:
			var resources_exist = self.world.data.terrain.data.resources.count > 0
			if resources_exist && ! self.entity.data.encounters.active:
				# get current tile
				var current_tile = self.Utils.get_object_by_grid(
					self.entity.data.grid_idx, self.world.data.terrain.data.tile_map)
				# check if tile contains resources,
				if current_tile.data.resources.food:
					# check if tile contains encounter
					var is_encounter = current_tile.data.encounters["spawn"].call(self.entity)
					# if encounter spawned,
					if is_encounter:
						# flag player as in active encounter
						self.entity.data.encounters.active = is_encounter
					# if no encounter spawned,
					else:
						## INTERACT
						var target_type = InteractAction.InteractTarget.RESOURCE
						var new_action = InteractAction.new(target_type)
						new_action.data.src = self.entity
						self.entity.data.actions.action = new_action
				
				# if current tile has no resources,
				else:
					# get the nearest resource tile
					var n_resource = self.entity.data.controller.find_nearest_resource(self.entity, self.world)
					## FIND
					var objective = FindAction.FindType.RESOURCE
					var new_action = FindAction.new(objective)
					new_action.data.src = self.entity
					new_action.data.target = n_resource
					self.entity.data.actions.action = new_action
			
			# if resources exist and player in encounter,
			elif resources_exist && self.entity.data.encounters.active:
					# check if encounter is complete
					var done = self.entity.data.controller.check_encounter(self.entity)
					# if encounter done,
					if done:
						## INTERACT
						var target_type = InteractAction.InteractTarget.RESOURCE
						var new_action = InteractAction.new(target_type)
						new_action.data.src = self.entity
						self.entity.data.actions.action = new_action
					
					# if encounter not done,
					else:
						## ATTACK
						# evaluate combat
						var encounter_controller = self.world.data.controller.terrain_controller.encounter_controller
						var active_encounter = encounter_controller.encounter
						var enemies = active_encounter.enemies.filter(func(e): return is_instance_valid(e) && e != null)
						## TODO: if multiple enemies, choose and maintain target instead of random
						var target = enemies.pick_random()
						# if target is valid, 
						if is_instance_valid(target):
							# TODO: add functional attack queue
							var new_action = _get_attack()
							new_action.data.src = self.entity
							new_action.data.target = target
							self.entity.data.actions.action = new_action
	
	# if enemy entity,
	elif self.entity is Enemy:
		## ATTACK
		# evaluate combat
		var terrain_controller = self.entity.data.world.data.controller.terrain_controller
		var encounter_controller = terrain_controller.encounter_controller
		# check if enemy is in encounter
		if self.entity.data.encounters.active:
			var active_encounter = encounter_controller.encounter
			var player = active_encounter.player
			var target = player
			# if target is valid, 
			if is_instance_valid(target):
				# TODO: add functional attack queue
				var new_action = _get_attack()
				new_action.data.src = self.entity
				new_action.data.target = target
				self.entity.data.actions.action = new_action
		
		# if encounter not active,
		else:
			## !! forcing enemy to avoid attacking until the action
			## !! cycle AFTER they have spawned ensures enemy/target
			## !! start encounter on same action cycle
			# make it active
			self.entity.data.encounters.active = true
	
	# try to evaluate the current action
	_evaluate_action()

## evaluates the currently active action for entity
func _evaluate_action():
	# get current action
	var current_action = self.entity.data.actions.action
	# don't process action if null
	# !! this means the only indication of a failed action
	# !! this should only happen if no valid action exists this cycle
	if current_action == null:
		return
	
	# match Action.Type
	match current_action.get_action_type():
		# FIND
		Action.ActionType.FIND:
			# move towards resource tile
			var action_target = current_action.data.target
			var result = self.entity.data.controller.move_towards_tile(
				self.entity, action_target)
			# if player is at find target,
			if result:
				# action done
				current_action.data.done = true
			else:
				# log update
				var action_v = current_action.get_action_string()
				var objective_v = current_action.get_objective_string()
				FileLogger.log_message(self , (
					self.entity.name + ": " + action_v + " " + objective_v
				), )

		# INTERACT
		Action.ActionType.INTERACT:
			# current tile should always be the interact target
			# get current tile
			var current_tile = self.Utils.get_object_by_grid(
				self.entity.data.grid_idx,
				self.world.data.terrain.data.tile_map)
			# interact with tile
			self.entity.data.controller.interact_with_tile(
				self.entity, current_tile)
		
		# ATTACK
		Action.ActionType.ATTACK:
			# do attack action to action.data.target
			if is_instance_valid(current_action.data.target):
				self.entity.data.controller.evaluate_combat(
					current_action)
	
	# if current action done,
	if current_action.data.done:
		if current_action is AttackAction:
			# TODO: process cooldown
			_add_cooldown(current_action, self.on_cooldown)


# Action Initialization

## called on script initialization
func _init(new_entity: Entity) -> void:
	# define controller entity on initialization
	self.entity = new_entity