extends Controller

# references
var player_scene = preload("res://src/entities/player/player.tscn")
<<<<<<< HEAD
=======
var movement_controller_script = preload("res://src/controllers/player/movement_controller.gd")
>>>>>>> 432b7a088b6d83cdee095d66db4ab258f2439182
var actions_controller_script = preload("res://src/controllers/player/actions_controller.gd")

var movement_controller: Controller
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
func _process_cycle_rewards(action: Action):
	# add exp to src if acquired resource
	if action.has_resource:
		action.src.data.actions.exp += (self.exp_rate)
	if action.encountered:
		action.src.data.actions.exp += int((self.exp_rate) * 1.5)
	
	# check if level_up
	var level_up = false
	if action.src.data.actions.exp >= self.exp_cap:
		## calculate player experience variables
		self.exp_step = (action.src.data.actions.level)
		self.exp_rate = floor((self.exp_step) + (PI * 10))
		self.exp_cap = floor((self.exp_step) * (self.exp_rate) * (PI * 10))
		# reset experience value
		action.src.data.actions.exp = 0
		# increment level
		action.src.data.actions.level += 1
		level_up = true
	
	# update exp_cap reference
	action.src.data.actions.exp_cap = self.exp_cap
	
	print(
		"src_lvl: " + str(action.src.data.actions.level) + " | ",
		"src_exp: " + str(action.src.data.actions.exp) + " | ",
		"exp_rate: " + str(self.exp_rate) + " | ",
		"exp_cap: " + str(self.exp_cap),
	)
	
	# log if level up
	if level_up:
		print(action.src.name + " is now level " + str(action.src.data.actions.level))


# determines and processes player logic for a single time cycle
func process_cycle():
	## General cycle logic
	## TODO: get player action
	## TODO: if valid, assign to player
	## TODO: if player valid, cycle complete
	self.cycle_complete = true


## TODO: initializes a new movement controller for a given player
func _init_movement_controller(p: Player):
	pass


## TODO: initializes a new actions controller for a given player
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


# initializes the player system controller
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
	new_player.data.stats.level = 1
	new_player.data.stats.exp = self.exp_rate
	new_player.data.stats.exp_cap = self.exp_cap

	var p = new_player
	self.add_child(new_player)
	
	# update uid ref
	world_controller.uid_ref += 1
	self.pid_ref += 1

	return p


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## TODO: account for multiple players
	# initialize the player entity as scene
	var new_player = _init_player_entity()
	if new_player:
		# initialize the actions controller on player
		new_player = _init_actions_controller(new_player)
		# if player still valid,
		if new_player:
			# update controller refs
			self.player = new_player