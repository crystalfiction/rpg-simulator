## Initializes and controls entity.world according to its dependencies
extends Controller

# utils
var utils_script = preload("res://src/controllers/utils/utils.gd")
var utils
var FileLogger
# script references
var terrain_controller_script = preload("res://src/controllers/world/terrain_controller.gd")
var player_controller_script = preload("res://src/controllers/entities/player/player_controller.gd")
var enemy_controller_script = preload("res://src/controllers/entities/enemy/enemy_controller.gd")
# scene references
var world_scene = preload("res://src/entities/world/world.tscn")
var time_controller_scene = preload("res://src/controllers/world/time_controller.tscn")
var ui_scene = preload("res://src/controllers/ui/ui_controller.tscn")
# controllers
var ui_controller: Control
var terrain_controller: Controller
var time_controller: Node2D
var player_controller: Controller
var enemy_controller: Controller
# components
var uid_ref = 0

## Ui Controllers

# initializes the ui controller scene
func _init_ui() -> Error:
	var new_ui = ui_scene.instantiate()
	new_ui.name = "UiController"
	new_ui.world = self.world
	self.ui_controller = new_ui
	add_child(new_ui)

	# validate result
	var result = OK
	if ! self.ui_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## Enemy Controllers

# initializes the enemy system controller script as object
func _init_enemy_controller() -> Error:
	var new_enemy_controller = self.enemy_controller_script.new()
	new_enemy_controller.name = "EnemyController"
	new_enemy_controller.world = self.world
	new_enemy_controller.parent = self
	self.enemy_controller = new_enemy_controller
	add_child(new_enemy_controller)
	
	# validate result
	var result = OK
	if ! self.enemy_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## Player Controllers

# initializes the player system controller script as object
func _init_player_controller() -> Error:
	var new_player_controller = self.player_controller_script.new()
	new_player_controller.name = "PlayerController"
	new_player_controller.world = self.world
	new_player_controller.parent = self
	new_player_controller.process_mode = Node.PROCESS_MODE_PAUSABLE
	self.player_controller = new_player_controller
	add_child(new_player_controller)
	
	# validate result
	var result = OK
	if ! self.player_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## World System Controllers

# initializes the time system controller script as object
func _init_time_controller() -> Error:
	var new_time_controller = self.time_controller_scene.instantiate()
	new_time_controller.name = "TimeController"
	new_time_controller.world = self.world
	new_time_controller.parent = self
	self.time_controller = new_time_controller
	add_child(new_time_controller)
	
	# validate result
	var result = OK
	if ! self.time_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the terrain system controller script as object
func _init_terrain_controller() -> Error:
	var new_terrain_controller = self.terrain_controller_script.new()
	new_terrain_controller.name = "TerrainController"
	new_terrain_controller.world = self.world
	new_terrain_controller.parent = self
	self.terrain_controller = new_terrain_controller
	add_child(new_terrain_controller)
	
	# validate result
	var result = OK
	if ! self.terrain_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the world entity as scene
func _init_world_entity() -> Error:
	# create new world obj
	var new_world = self.world_scene.instantiate()
	new_world.name = "World"
	var screen_size = get_tree().root.size
	new_world.texture.width = screen_size.x
	new_world.texture.height = screen_size.y
	self.world = new_world
	add_child(new_world)
	
	# set data after entity enters scene to overwrite
	# init data
	new_world.data.controller = self
	
	# validate result
	var result = OK
	if ! self.world:
		result = ERR_INVALID_PARAMETER
	return result


# fully reloads the current world_controller scene
func reload_world() -> void:
	## TODO: account for lingering null references to deleted objs
	get_tree().reload_current_scene()


# initializes controller dependencies
func _init_controllers() -> void:
	# init controller utils script
	var new_utils = self.utils_script.new()
	if new_utils:
		self.utils = new_utils
	else:
		FileLogger.log_message("Failed to intiialize utils.")
	
	# init functions array
	var init_controllers = [
		_init_world_entity(),
		_init_terrain_controller(),
		_init_player_controller(),
		_init_enemy_controller(),
		_init_time_controller(),
		# _init_ui(),
	]
	# run init scrips
	for s in range(init_controllers.size()):
		var result = init_controllers[s]
		# if error initializing...
		if result != OK:
			# print error & pause tree
			FileLogger.log_message(error_string(result) + " at script " + str(s))
			self.get_tree().paused = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.FileLogger = $"/root/FileLogger"
	FileLogger.log_message("Initializing world...")
	
	# initialize controller dependencies
	_init_controllers()

	FileLogger.log_message("World initialized.")


## accepts current world entity,
## validates world data and returns result flag
func _process_cycle(current_world: Entity):
	# if time_controller is cycling,
	if self.time_controller.cycling:
		# result is OK unless otherwise specified,
		if current_world:
			# process conditions depending on World.data
			# if player dead,
			if self.world.data.player == null:
				# game is over,
				FileLogger.log_message("Game over.")
				# reload world
				reload_world()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process cycle
	_process_cycle(self.world)
