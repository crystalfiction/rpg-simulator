## Initializes and controls entity.world according to its dependencies
extends Controller

# utils
var world_utils_script = preload("res://src/world_utils.gd")
var utils
# references
var terrain_controller_script = preload("res://src/controllers/world/terrain_controller.gd")
var player_controller_script = preload("res://src/controllers/player/player_controller.gd")
# entities
var ui_scene = preload("res://src/controllers/ui/ui_controller.tscn")
var world_scene = preload("res://src/entities/world/world.tscn")
var time_controller_scene = preload("res://src/controllers/world/time_controller.tscn")
# controllers
var ui_controller
var terrain_controller: Controller
var time_controller: Node2D
var player_controller: Controller
# components
var uid_ref = 0

## Ui Controllers

# initializes the ui controller scene
func _init_ui():
	var new_ui = ui_scene.instantiate()
	new_ui.name = "UiController"
	new_ui.world = self.world
	self.ui_controller = new_ui
	add_child(new_ui)

	# validate result
	var result = true
	if ! self.ui_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## Player Controllers

# initializes the player system controller script as object
func _init_player_controller():
	var new_player_controller = self.player_controller_script.new()
	new_player_controller.name = "PlayerController"
	new_player_controller.world = self.world
	self.player_controller = new_player_controller
	add_child(new_player_controller)
	
	# validate result
	var result = true
	if ! self.player_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## World System Controllers

# initializes the time system controller script as object
func _init_time_controller():
	var new_time_controller = self.time_controller_scene.instantiate()
	new_time_controller.name = "TimeController"
	new_time_controller.world = self.world
	self.time_controller = new_time_controller
	add_child(new_time_controller)
	
	# pause time controller tree until world initialized
	self.time_controller.get_tree().paused = true
	
	# validate result
	var result = true
	if ! self.time_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the terrain system controller script as object
func _init_terrain_controller():
	var new_terrain_controller = self.terrain_controller_script.new()
	new_terrain_controller.name = "TerrainController"
	new_terrain_controller.world = self.world
	self.terrain_controller = new_terrain_controller
	add_child(new_terrain_controller)
	
	# validate result
	var result = true
	if ! self.terrain_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the world entity as scene
func _init_world_entity():
	# create new world obj
	var new_world = self.world_scene.instantiate()
	new_world.name = "World"
	new_world.data.controller = self
	var screen_size = get_tree().root.size
	new_world.texture.width = screen_size.x
	new_world.texture.height = screen_size.y
	self.world = new_world
	add_child(new_world)
	
	# validate result
	var result = true
	if ! self.world:
		result = ERR_INVALID_PARAMETER
	return result


# reloads the current world_controller scene
func reload_world():
	## TODO: account for lingering null references to deleted objs
	get_tree().reload_current_scene()


# initializes controller dependencies
func _init_controllers():
	# init world_utils script
	var new_world_utils = world_utils_script.new()
	utils = new_world_utils
	if !utils:
		print("World utils error.")
	
	# init functions array
	var init_controllers = [
		_init_world_entity(),
		_init_terrain_controller(),
		_init_player_controller(),
		_init_time_controller(),
	]
	# run init scrips
	for s in range(init_controllers.size()):
		var result = init_controllers[s]
		# if error initializing...
		if result is Error:
			# print error & pause tree
			print(error_string(result) + " at script " + str(s))
			self.get_tree().paused = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Initializing world...")
	
	# initialize controller dependencies
	_init_controllers()
	
	print("World initialized.")

	# initialization process was valid,
	# start time system
	print("Starting time system...")
	self.time_controller.get_tree().paused = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
