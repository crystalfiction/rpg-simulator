extends Controller

# references
var player_controller: Controller
# components
var frames = 0
var frame_rate = 15
var double_speed = false
var cycles = 0
# state processing
var dependencies = []
var processing_array = []
var cycling = null
var cycle_complete = null


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
			self.frame_rate = 10
		else:
			print("1x speed")
			self.frame_rate = 15


# checks if controllers in processing_array are done cycling
func _check_cycle_completion():
	# check conditions
	var all_done = false
	for c in processing_array:
		if c.cycle_complete:
			all_done = true
		# cycle should be complete,
		else:
			# a controller was not fully processed...
			print("Loose controller thread detected.")

	
	# if all controller cycles complete...
	if all_done:
		# reset cycle
		_reset_time_cycle()


# resets all relevant time cycle processing variables
func _reset_time_cycle():
	# loop through processing_array,
	for p in range(self.processing_array.size()):
		# reset controller state
		self.processing_array[p].cycle_complete = false
	
	# set empty processing array
	var new_array = []
	self.processing_array = new_array

	# update time_controller vars
	self.cycling = false
	self.cycle_complete = false


## main entry point of the time system
func _process_time_cycle():
	print("Starting time cycle" + " " + str(self.cycles + 1) + ".")
	
	# check controllers for time cycle processing
	for d in self.dependencies:
		## primary time cycle
		# if controller has cycle function...
		if d.has_method("process_cycle"):
			# append to processing array, if missing
			if d not in self.processing_array:
				self.processing_array.append(d)
				# update processing state since array changed
				self.cycling = self.processing_array.size() > 0
				
			# process controller cycle
			d.process_cycle()

	# watch for completion at end of cycle
	_check_cycle_completion()


# initializes controller dependencies
func _init_controller():
	# initialize controller references
	## ORDERING MATTERS
	player_controller = world.data.controller.player_controller
	# append to dependencies array
	dependencies.append_array([
		player_controller,
	])
	
	# initialize time system
	frames = 0
	cycle_complete = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# initialize the controller
	_init_controller()

	print("Time initialized.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# only process specific things if tree is paused
	if !get_tree().paused:
		# update frames
		frames += 1
		
		# check for frame interval
		if self.frames % self.frame_rate == 0:
			# process controllers
			_process_time_cycle()
			
			# update cycle count
			self.cycles += 1
