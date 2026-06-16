class_name ActionController extends Controller

# refs
var entity: Entity
var on_cooldown: Array = []


# Cooldowns

## gets the next available attack in entity abilities queue
func _cooldown_summary() -> String:
	var entries: Array = []
	for c in self.on_cooldown:
		var remaining = c.data.cooldown_remaining if "cooldown_remaining" in c.data else c.data.cooldown
		entries.append(c.get_attack_type_string() + "(" + str(remaining) + ")")
	var summary = ""
	for i in range(entries.size()):
		summary += entries[i]
		if i < entries.size() - 1:
			summary += ", "
	return summary

func _get_attack() -> AttackAction:
	var new_action = null
	# if abilities array,
	if "abilities" in self.entity.data.actions:
		var abilities = self.entity.data.actions.abilities
		for a in abilities:
			var new_a = a.new()
			# only select ability if same-type not on cooldown
			if not _check_cooldowns(new_a, self.on_cooldown):
				new_action = new_a
				return new_action

		# if we reached here no ability was selectable (all on cooldown)
		# fallback to a BasicAttack so entity still has an action
		new_action = BasicAttack.new()
		return new_action

	# if no abilities array,
	else:
		# assign basic attack
		new_action = BasicAttack.new()

	return new_action

## checks whether or not the passed action exists in any context
## (instance, type) in cooldowns array
func _check_cooldowns(action: AttackAction, cooldowns: Array) -> bool:
	# Basic attacks are always available; never considered on cooldown
	if action.get_attack_type() == AttackAction.AttackType.BASIC:
		return false
	# return true if any cooldown entry matches the action type
	var atype = action.get_attack_type()
	for c in cooldowns:
		if c.get_attack_type() == atype:
			return true
	return false

## puts an action on cooldown by adding to on_cooldown array
func _add_cooldown(action: AttackAction, cooldowns: Array):
	# Basic attacks should never be put on cooldown
	if action.get_attack_type() == AttackAction.AttackType.BASIC:
		return
	# going on cooldown,
	if "cooldown" in action.data:
		var exists = _check_cooldowns(action, cooldowns)
		if action.data.cooldown > 0 and not exists:
			# cooldown should block the next N cycles after this action completes
			action.data.cooldown_remaining = int(action.data.cooldown) + 1
			cooldowns.append(action)

## handles on_cooldown array
func _handle_cooldowns(cooldowns: Array) -> Array:
	# on cooldown,
	if cooldowns.size() > 0:
		# iterate backwards so removals are safe
		for i in range(cooldowns.size() - 1, -1, -1):
			var c = cooldowns[i]
			if "cooldown_remaining" in c.data:
				c.data.cooldown_remaining = int(c.data.cooldown_remaining) - 1
				if c.data.cooldown_remaining <= 0:
					cooldowns.remove_at(i)
			# fallback: legacy "cooldown" field
			elif "cooldown" in c.data:
				c.data.cooldown = int(c.data.cooldown) - 1
				if c.data.cooldown <= 0:
					cooldowns.remove_at(i)
	return cooldowns

func get_action():
	# action is null if world complete
	if self.world.data.terrain.data.map_complete:
		self.entity.data.actions.action = null
		return

	# debug: trace action cycle entry
	# handle action cooldowns every cycle
	self.on_cooldown = _handle_cooldowns(self.on_cooldown)

	# if there's already an active action, evaluate it and don't replace
	if "actions" in self.entity.data and self.entity.data.actions.action != null:
		_evaluate_action()
		return

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
			
			# if player in encounter, regardless of remaining resource count
			elif self.entity.data.encounters.active:
				# check if encounter is complete
				var done = self.entity.data.controller.check_encounter(self.entity)
				# if encounter done,
				if done:
					## INTERACT
					var target_type = InteractAction.InteractTarget.RESOURCE
					var new_action = InteractAction.new(target_type)
					new_action.data.src = self.entity
					self.entity.data.actions.action = new_action
				
				# if still encountering,
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
	# if an action is null, no action to be evaluated
	if current_action == null:
		return
	# if an attack has no valid target, clear it so a new one can be chosen
	if current_action.get_action_type() == Action.ActionType.ATTACK and not is_instance_valid(current_action.data.target):
		current_action.data.done = true
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
				# Basic attacks should resolve immediately and never occupy multiple cycles
				if current_action.get_attack_type() == AttackAction.AttackType.BASIC:
					self.entity.data.controller.evaluate_combat(current_action)
				else:
					# determine duration (require explicit duration)
					var dur = null
					if "duration" in current_action.data:
						dur = ceil(current_action.data.duration)
					if dur != null:
						if "duration_remaining" not in current_action.data:
							current_action.data.duration_remaining = int(dur)
						current_action.data.duration_remaining = int(current_action.data.duration_remaining) - 1
						if current_action.data.duration_remaining <= 0:
							self.entity.data.controller.evaluate_combat(current_action)

	# if current action done,
	if current_action.data.done:
		# record last action performed for UI visibility (helps 1-cycle actions)
		if "last_action" in self.entity.data.actions:
			# store readable script name
			self.entity.data.actions.last_action = current_action.get_script().get_global_name()
		if current_action is AttackAction:
			_add_cooldown(current_action, self.on_cooldown)

		# clear action so next cycle can select a new one
		self.entity.data.actions.action = null

# Action Initialization
## called on script initialization
func _init(new_entity: Entity) -> void:
	# define controller entity on initialization
	self.entity = new_entity