extends Controller

# references
var FileLogger
var terrain_controller: Controller
var player_controller: Controller
var enemy_controller: Controller
var encounter_controller: Controller
# components
var frames: int = 0
var frame_rate: int = 5
var frame_rates: Array = [
	21,
	13, # default
	5,
	1, # TODO: only for dev
]

var cycle_time: float = 1
var cycles: int = 0
var cycling: bool = false


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
	
	# shortcuts: =
	if event.is_action_pressed("world_tick_inc"):
		var current_speed = self.frame_rates.find(self.frame_rate)
		var new_speed = clamp(current_speed + 1, 0, self.frame_rates.size() - 1)
		self.frame_rate = self.frame_rates[new_speed]
		print("World tick rate: " + str(self.frame_rate))
	
	# shortcuts: -
	if event.is_action_pressed("world_tick_dec"):
		var current_speed = self.frame_rates.find(self.frame_rate)
		var new_speed = clamp(current_speed - 1, 0, self.frame_rates.size() - 1)
		self.frame_rate = self.frame_rates[new_speed]
		print("World tick rate: " + str(self.frame_rate))
		

## initializes controller dependencies
func _init_controller():
	# initialize time system
	self.frames = 0

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
