extends Controller

# references
var terrain_controller: Controller
var player_controller: Controller
var enemy_controller: Controller
var encounter_controller: Controller
# components
var frames = 0
var frame_rate = 50
var double_speed = false

var dependencies = []
var processing_array = []
var cycles = 0
var cycling = null


# check for inputs
func _unhandled_input(event: InputEvent) -> void:
	# shortcuts: t, space
	if event.is_action_pressed("world_pause"):
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			print("World paused.")
		else:
			print("World unpaused.")
	
	# shortcuts: r
	if event.is_action_pressed("world_reload"):
		self.world.data.controller.reload_world()
	
	# shortcuts: s
	if event.is_action_pressed("world_speed"):
		# double the frame rate
		self.double_speed = ! self.double_speed
		if self.double_speed:
			print("1.5x speed")
			self.frame_rate = 18
		else:
			print("1x speed")
			self.frame_rate = 30


# initializes controller dependencies
func _init_controller():
	# initialize time system
	frames = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# initialize the controller
	_init_controller()
	print("Time initialized.")


func _process_cycle():
	# update frames
	frames += 1
	
	# only process cycle if tree !paused
	if !get_tree().paused:
		# if frame interval,
		if self.frames % self.frame_rate == 0:
			# update cycle count
			self.cycles += 1
			# flag time as cycling
			self.cycling = true
			# TODO: do time processing
		# if not frame interval,
		else:
			# not cycling
			self.cycling = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process cycle
	_process_cycle()
