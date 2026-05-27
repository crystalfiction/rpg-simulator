extends Controller

# references
var player_scene = preload("res://src/entities/player/player.tscn")
var movement_controller_script = preload("res://src/controllers/player/movement_controller.gd")
var action_controller_script = preload("res://src/controllers/player/action_controller.gd")

# controllers
var movement_controller: Controller
var action_controller: Controller
# entities
var player: Player
# components
var pid_ref = 0
var cycle_complete = false
# movement
var player_speed = 1
# experience
var exp_step: int
var exp_rate: int
var exp_cap: int


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
	# get player action
	# var new_action = self.action_controller.get_action(self.player)
	# if valid, assign to player
	# if player valid, cycle complete
	self.cycle_complete = true


# initializes the player system controller
func _init_player():
	var world_controller = self.world.data.controller
	var new_player = self.player_scene.instantiate()
	# init data
	new_player.data.uid = world_controller.uid_ref
	new_player.data.pid = self.pid_ref
	new_player.name = "player_" + str(new_player.data.pid)
	new_player.world = self.world
	new_player.data.controller = self
	self.player = new_player
	self.add_child(new_player)
	# update uid ref
	world_controller.uid_ref += 1
	self.pid_ref += 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## TODO: will need to update for multiple players
	# init player component data
	self.exp_step = (1)
	self.exp_rate = floor((self.exp_step) + (PI * 10))
	self.exp_cap = floor((self.exp_step) * (self.exp_rate) * (PI * 10))
	
	# initialize the player scene
	_init_player()

	if self.player:
		print("Player initialized.")
