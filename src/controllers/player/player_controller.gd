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
# experience
var exp_step: int
var exp_rate: int
var exp_cap: int


# determines and processes player logic for a single time cycle
func process_cycle():
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
	# initialize the player object
	_init_player()

	# validate player
	if self.player:
		print("Player initialized.")
