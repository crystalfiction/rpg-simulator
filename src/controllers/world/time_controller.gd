extends Controller

# references
var terrain_controller: Controller
var player_controller: Controller
var enemy_controller: Controller
var encounter_controller: Controller
# components
var frames: float = 0.0
var time_scale: float = 60.0
var frame_rates: Array = [
	10,
	5,
	1
]
# default to middle index if available
var frame_rate: int = frame_rates[floor(frame_rates.size() / 2.0)] if frame_rates.size() > 2 else frame_rates[0]

var cycling: bool = false
var cycles: int = 0

# var seconds: int = 0
# var minutes: int = 0
# var hours: int = 0
# var days: int = 0
# var weeks: int = 0
# var months: int = 0
# var years: int = 0

var data = {
	"frame_rate": 0,
	"cycles": 0,
}


func _update_time_stats(curr_cycles: int):
	# self.seconds = curr_cycles
	# self.minutes = floor(seconds / time_scale)
	# self.hours = floor(minutes / time_scale)
	# self.days = floor(hours / 24.0)
	# self.weeks = floor(days / 7.0)
	# self.months = floor(weeks / 4.0)
	# self.years = floor(months / 12.0)
	var new_time_data = {
		"frames": self.frames,
		"frame_rate": self.frame_rate,
		"cycles": curr_cycles,
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get FileLogger
	self.FileLogger = $"/root/FileLogger"
	FileLogger.log_message(self , "Time initialized.")


# Time Processing

## checks whether time cycle conditions are currently valid
func _check_cycle_conditions() -> bool:
	var conditions = (
		self.world &&
		self.world.data.terrain &&
		"weather" in self.world.data.terrain.data &&
		"resources" in self.world.data.terrain.data
	)
	return true if conditions else false

## process time-level data for cycle
func _process_cycle(delta: float):
	# only process cycle if tree !paused
	var cycle_conditions = _check_cycle_conditions()
	if get_tree().paused or not cycle_conditions:
		self.cycling = false
		return

	# accumulate frames using delta to be framerate-independent
	frames += delta * time_scale

	var interval = float(self.frame_rate)
	# if we've reached or passed the interval, consume interval and advance cycle
	if frames >= interval:
		# consume the interval (allow leftover for next interval)
		frames -= interval
		self.cycles += 1
		self.cycling = true
		_update_time_stats(self.cycles)
		if self.FileLogger:
			FileLogger.log_message(self , "Starting cycle " + str(self.cycles))
	else:
		self.cycling = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# keep data.frame_rate up-to-date
	self.data["frame_rate"] = self.frame_rate
	# process cycle with delta
	_process_cycle(delta)
