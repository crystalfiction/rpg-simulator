class_name ActionController extends Controller

# refs
var entity: Entity


## gets a new action for parent entity,
## to be evaluated over one or more cycles by evaluate_action
func get_action():
	# if Player entity,
	if self.entity is Player:
		# if resources exist and player not in encounter,
		var resources_exist = self.world.data.terrain.resources.count > 0
		if resources_exist && ! self.entity.data.encounters.active:
			## FIND
			## TODO: this doesn't make sense as its own action until
			## travel time is added to movement
			# find the nearest resource
			var n_resource = self.entity.data.controller.find_nearest_resource(self.entity, self.world)
			# move to tile
			self.entity.data.controller.move_to_tile(self.entity, n_resource)
			# check if tile contains encounter
			var is_encounter = n_resource.data.encounters["spawn"].call(self.entity)
			# if encounter spawned,
			if is_encounter:
				# flag player as in active encounter
				self.entity.data.encounters.active = is_encounter
			# if no encounter spawned,
			else:
				## INTERACT
				var target_type = InteractAction.InteractTarget.RESOURCE
				var new_action = InteractAction.new(target_type)
				new_action.src = self.entity
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
					new_action.src = self.entity
					self.entity.data.actions.action = new_action
				
				# if encounter not done,
				else:
					## ATTACK
					# evaluate combat
					var encounter_controller = self.world.data.controller.terrain_controller.encounter_controller
					var active_encounter = encounter_controller.encounter
					var enemies = active_encounter.enemies.filter(func(e): return is_instance_valid(e) && e != null)
					## TODO: choose and maintain target instead of random
					var target = enemies.pick_random()
					# if target is valid, 
					if is_instance_valid(target):
						# assign attack action
						var new_action = AttackAction.new()
						new_action.src = self.entity
						new_action.target = target
						self.entity.data.actions.action = new_action
	
	# if enemy entity,
	elif self.entity is Enemy:
		## ATTACK
		# evaluate combat
		var encounter_controller = self.world.data.controller.terrain_controller.encounter_controller
		var active_encounter = encounter_controller.encounter
		var player = active_encounter.player
		var target = player
		# if target is valid, 
		if is_instance_valid(target):
			# assign attack action
			var new_action = AttackAction.new()
			new_action.src = self.entity
			new_action.target = target
			self.entity.data.actions.action = new_action


## evaluates the currently active action for entity
func evaluate_action():
	# get current action
	var current_action = self.entity.data.actions.action
	# don't process action if null
	# !! this means the only indication of a failed action
	# !! is contextual, fails silently
	if current_action == null:
		return
	
	# match Action.Type
	match current_action.get_action_type():
		# FIND
		Action.ActionType.FIND:
			# do find action
			pass
		
		# INTERACT
		Action.ActionType.INTERACT:
			# current tile should always be the interact target
			# get current tile
			var utils = self.world.data.controller.utils
			var current_tile = utils.get_object_by_grid(
				self.entity.data.grid_idx,
				self.world.data.terrain.tile_map)
			# interact with tile
			self.entity.data.controller.interact_with_tile(
				self.entity, current_tile)
			# flag action complete
			current_action.done = true
		
		# ATTACK
		Action.ActionType.ATTACK:
			# do attack action to action.target
			if is_instance_valid(current_action.target):
				self.entity.data.controller.evaluate_combat(
					current_action)
	
	# if current action done,
	if current_action.done:
		# update action history
		self.entity.data.actions.history.append(current_action)
		# null action in player data
		self.entity.data.actions.action = null


## called on script initialization
func _init(new_entity: Entity) -> void:
	# define controller entity on initialization
	self.entity = new_entity


func _process(delta: float) -> void:
	pass