extends Controller

# refs
var player: Player


# checks a neighbors array for the passed resource objective
func _check_neighbors(objective: FindAction.FindTarget, neighbors: Array):
	# TODO: check if neighbors have resources
	var n_objectives = []
	for n in neighbors:
		# if current find objective is resource,
		if objective == FindAction.FindTarget.RESOURCE:
			# check for food, as food is currently only resource
			if n.data.resources.food:
				n_objectives.append(n)
	return n_objectives


## returns tile 1 grid tile towards target
func _move_in_direction(target: Tile):
	var world_controller = self.world.data.controller
	var tile_map = self.world.data.terrain.tile_map
	# get neighbor tiles of player
	var neighbors = world_controller.utils.get_neighbors(self.player, tile_map)
	# determine which neighbor is closest to target
	# sort neighbors by distance to target
	var n_neighbors = neighbors
	n_neighbors.sort_custom(func(a, b): return (
		abs((target.global_position - a.global_position)) <
		abs((target.global_position - b.global_position))
	))
	# get the nearest neighbor
	var n_neighbor = n_neighbors.front()
	# return position
	return n_neighbor


# determines the nearest objective of a FindAction
# depending on its FindTarget and returns its tile
func _find_nearest_objective(objective: FindAction.FindTarget) -> Tile:
	# refs
	var world_controller = self.world.data.controller
	var tile_map = self.world.data.terrain.tile_map
	# if player is currently finding resources,
	if objective == FindAction.FindTarget.RESOURCE:
		# define target
		var n_objective: Tile
		## TODO: get k neighbors of player tile until resource found 
		# define done condition
		var done = false
		var k = 1
		# while not done,
		while !done:
			# TODO: get k neighbors of current tile
			var neighbors = world_controller.utils.get_k_neighbors(
				self.player, tile_map, k)
			# check neighbors for resources
			var n_resources = _check_neighbors(objective, neighbors)
			# if neighbors have resources, pick a random neighbor
			if n_resources.size() > 0:
				n_objective = n_resources.pick_random()
				# stop looping
				done = true
			# if no resources found,
			else:
				# continue looping
				# increment k
				k += 1
		
		# return nearest objective tile
		return n_objective
	
	# if player is finding something else
	else:
		# return current tile for now
		var current_tile = world_controller.utils.get_object_by_grid(
			self.player.data.grid_idx, tile_map
		)
		return current_tile


## TODO: evaluates the player's current action given world conditions
func evaluate_action():
	# get current action
	var current_action = self.player.data.actions.action
	
	# break if null
	if current_action == null:
		return ERR_INVALID_PARAMETER
	
	# evaluate action logic
	print(current_action.get_action_string())
	match current_action.Type:
		# 0: IDLE,
		Action.ActionType.IDLE:
			# TODO: idle logic...
			pass

		# 1: FIND
		Action.ActionType.FIND:
			# TODO: find logic...
			# get find objective
			var objective = current_action.Objective
			# determine nearest location of objective
			var n_objective = _find_nearest_objective(objective)
			# if player is not at objective,
			if self.player.position != n_objective.position:
				# move to neighbor in direction nearest to target
				var target_tile = _move_in_direction(n_objective)
				# try to lerp to new pos
				self.player.position = lerp(
					self.player.position,
					target_tile.position,
					1 # move completely to new position
				)
				# update grid_idx
				var world_controller = self.world.data.controller
				self.player.data.grid_idx = world_controller.utils.world_to_grid(
					self.player.global_position,
					world_controller.terrain_controller.grid_scale
				)
			# if player is at objective tile,
			else:
				# action is complete
				current_action.done = true
				print("Resource found.")

		# 2: INTERACT
		Action.ActionType.INTERACT:
			# TODO: interact logic...
			pass

	# return current action
	return current_action


# gets and returns a new action for the player
# returns current action if incomplete
func get_action():
	var new_action: Action
	# check if player has action
	# if not, 
	if self.player.data.actions.action == null:
		# determine if the world contains resources
		# get terrain data
		var terrain = self.world.data.terrain
		# check if resources
		if terrain.resources.count > 0:
			# if so, create new FindAction
			var objective = FindAction.FindTarget.RESOURCE
			new_action = FindAction.new(objective)
			new_action.src = self.player
		# if no resources in world, map complete
		else:
			# notify terrain_controller
			var terrain_controller = (
				self.world.data.controller.terrain_controller)
			terrain_controller.map_complete = true
			# create new IdleAction
			new_action = IdleAction.new()
			new_action.src = self.player

		# current action is always null if here
		# update the player entity
		self.player.data.actions.action = new_action
	
	# already has action, check completion conditions
	else:
		var current_action = self.player.data.actions.action
		# if current_action is valid,
		if current_action is Action:
			# if action is complete,
			if current_action.done:
				## TODO: determine new action
				pass
			
			# if action not complete,
			else:
				# return current action
				new_action = current_action

	# return new action
	return new_action
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
