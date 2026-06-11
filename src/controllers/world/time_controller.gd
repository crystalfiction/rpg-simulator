extends Controller

# references
var FileLogger
var terrain_controller: Controller
var player_controller: Controller
var enemy_controller: Controller
var encounter_controller: Controller
# components
var frames: float = 0.0
var time_scale: float = 60.0
var frame_rate: int = 15
var frame_rates: Array = [
	30,
	15, # default
	8,
	5,
	1
]

var cycling: bool = false
var cycles: int = 0

var seconds: int = 0
var minutes: int = 0
var hours: int = 0
var days: int = 0
var weeks: int = 0
var months: int = 0
var years: int = 0

var data = {
	"frame_rate": 0,
	"cycles": 0,
	"seconds": 0,
	"minutes": 0
}


func _update_time_stats(curr_cycles: int):
	self.seconds = curr_cycles
	self.minutes = floor(seconds / time_scale)
	self.hours = floor(minutes / time_scale)
	self.days = floor(hours / 24.0)
	self.weeks = floor(days / 7.0)
	self.months = floor(weeks / 4.0)
	self.years = floor(months / 12.0)

	var new_time_data = {
		"frames": self.frames,
		"frame_rate": self.frame_rate,
		"cycles": self.cycles,
		"seconds": self.seconds,
		"minutes": self.minutes,
	}
	self.data = new_time_data

## handles user inputs depending on Input Map actions
func _unhandled_input(event: InputEvent) -> void:
	# shortcuts: r
	if event.is_action_pressed("world_reload"):
		get_tree().reload_current_scene()
	
	# shortcuts: s
	if event.is_action_pressed("world_pause"):
		get_tree().set_deferred("paused", not get_tree().paused)

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
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get FileLogger
	self.FileLogger = $"/root/FileLogger"

	# initialize the controller
	_init_controller()
	
	FileLogger.log_message(self , "Time initialized.")

## process time-level data for cycle
func _process_cycle():
# only process cycle if tree !paused
	# update frames
	if !get_tree().paused && self.world:
		frames += time_scale
		# if frame interval,
		if int(self.frames) % int(self.frame_rate * time_scale) == 0:
			# update cycle count
			self.cycles += 1
			# flag time as cycling
			self.cycling = true
			# TODO: do time processing
			FileLogger.log_message(self , "Starting cycle " + str(self.cycles))
			# process time stats
			_update_time_stats(self.cycles)

		# if not frame interval,
		else:
			# not cycling
			self.cycling = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process cycle
	_process_cycle()
