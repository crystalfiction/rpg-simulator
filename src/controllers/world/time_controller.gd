extends Controller

# references
var FileLogger
var terrain_controller: Controller
var player_controller: Controller
var enemy_controller: Controller
var encounter_controller: Controller
# components
var frames = 0
var frame_rate = 30
var double_speed = true # TODO: debugging

var dependencies = []
var processing_array = []
var cycles = 0
var cycling = null


## handles user inputs depending on Input Map actions
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
		get_tree().reload_current_scene()
	
	# shortcuts: s
	if event.is_action_pressed("world_speed"):
		# double the frame rate
		self.double_speed = ! self.double_speed
		if self.double_speed:
			print("2x speed")
			self.frame_rate = 15
		else:
			print("1x speed")
			self.frame_rate = 30

## initializes controller dependencies
func _init_controller():
	# initialize time system
	self.frames = 0
	self.frame_rate = (self.frame_rate / 2) if (self.double_speed) else (self.framerate)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get FileLogger
	self.FileLogger = $"/root/FileLogger"

	# initialize the controller
	_init_controller()
	FileLogger.log_message(self , "Time initialized.")

## process time-level data for cycle
func _process_cycle():
	# update frames
	frames += 1
	
	# only process cycle if tree !paused
	if !get_tree().paused && self.world:
		# if frame interval,
		if self.frames % self.frame_rate == 0:
			# update cycle count
			self.cycles += 1
			# flag time as cycling
			self.cycling = true
			# TODO: do time processing
			FileLogger.log_message(self , "Starting cycle " + str(self.cycles))
		# if not frame interval,
		else:
			# not cycling
			self.cycling = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process cycle
	_process_cycle()
