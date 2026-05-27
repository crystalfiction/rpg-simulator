extends Controller

# refs
var player: Player


## TODO: evaluates the player's current action given world conditions
func evaluate_action():
	pass


# gets and returns a new action for the player
# returns current action if incomplete
func get_action():
	# check if player has action
	var new_action: Action
	if self.player.data.actions.action == null:
		# if not, determine if the world contains resources
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

		# update the player entity
		self.player.data.actions.action = new_action
	
	# already has action
	else:
		# if current_action is valid,
		var current_action = self.player.data.actions.action
		if current_action is Action:
			# do nothing
			new_action = current_action

	return new_action
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
