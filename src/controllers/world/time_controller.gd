extends Controller

# references
var player_controller: Controller
# components
var frames = 0
var frame_rate = 50
var double_speed = false

var dependencies = []
var processing_array = []
var cycles = 0
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
			self.frame_rate = 18
		else:
			print("1x speed")
			self.frame_rate = 30


# checks if controllers in processing_array are done cycling
func _check_cycle_completion():
	# check conditions
	var all_done = false
	# if still cycling but nothing in processing,
	if self.cycling && self.processing_array.size() == 0:
		# cycle should be complete in this case
		self.cycle_complete = true
		# flag all_done true as there are no controllers in processing
		all_done = true
	
	# if processing as expected,
	if self.cycling && self.processing_array.size() > 0:
		# check controller cycles
		for c in processing_array:
			# if controller cycle complete,
			if c.cycle_complete:
				all_done = true
			# controller cycle should be complete,
			else:
				# a controller thread was not fully processed...
				# don't start next cycle until thread is resolved
				print("Loose controller thread detected at " + c.name)

	# if all controller cycles complete...
	if all_done:
		# flag cycle complete
		self.cycle_complete = true
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

	# unpause tree
	get_tree().paused = false


## main entry point of the time system
## cycling -> a dependency controller is in processing
## not cycling -> time is ready to process next cycle
func _process_time_cycle():
	# if time still processing,is not done processing last cycle 
	# and is therefor loose
	if self.cycling && ! self.cycle_complete:
		# do not start another cycle until current complete
		# check for cycle completion and break
		_check_cycle_completion()
		return

	print("Starting time cycle" + " " + str(self.cycles) + ".")
	
	## Primary Loop Cycle
	# check controllers for time cycle processing,
	for d in self.dependencies:
		# if controller has cycle function,
		if d.has_method("process_cycle"):
			# append to processing array, if missing
			if d not in self.processing_array:
				self.processing_array.append(d)
				# update processing state since array changed
				self.cycling = self.processing_array.size() > 0
				
			# process controller cycle
			d.process_cycle()

	# pause tree until controllers done processing
	get_tree().paused = true


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
	# update frames
	frames += 1
	
	# if frame interval,
	if self.frames % self.frame_rate == 0:
		# only process cycle if tree !paused
		if !get_tree().paused:
			# update cycle count
			self.cycles += 1
				
			# process controllers
			_process_time_cycle()
		
		# tree paused,
		else:
			# do something
			# check for cycle completion
			_check_cycle_completion()
