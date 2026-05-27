## Primary entrypoint and parent for world components
extends Controller

# utils
var world_utils_script = preload("res://src/world_utils.gd")
var utils
# references
var terrain_controller_script = preload("res://src/controllers/world/terrain_controller.gd")
var weather_controller_script = preload("res://src/controllers/world/weather_controller.gd")
var resource_controller_script = preload("res://src/controllers/world/resource_controller.gd")
var player_controller_script = preload("res://src/controllers/player/player_controller.gd")
var encounter_controller_script = preload("res://src/controllers/world/encounter_controller.gd")
# entities
var ui_scene = preload("res://src/controllers/ui/ui_controller.tscn")
var world_scene = preload("res://src/entities/world/world.tscn")
var time_controller_scene = preload("res://src/controllers/world/time_controller.tscn")
# controllers
var ui_controller
var terrain_controller: Controller
var weather_controller: Controller
var resource_controller: Controller
var player_controller: Controller
var encounter_controller: Controller
var time_controller: Node2D
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
	if !ui_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## Player Controllers

# initializes the player system controller script as object
func _init_player():
	var new_player_controller = self.player_controller_script.new()
	new_player_controller.name = "PlayerController"
	new_player_controller.world = self.world
	player_controller = new_player_controller
	add_child(new_player_controller)
	
	# validate result
	var result = true
	if !player_controller:
		result = ERR_DOES_NOT_EXIST
	return result


## World System Controllers

# initializes the time system controller script as object
func _init_time():
	var new_time_controller = self.time_controller_scene.instantiate()
	new_time_controller.name = "TimeController"
	new_time_controller.world = self.world
	time_controller = new_time_controller
	add_child(new_time_controller)
	
	# validate result
	var result = true
	if !time_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the encounters system controller script as object
func _init_encounters():
	var new_encounter_controller = self.encounter_controller_script.new()
	new_encounter_controller.name = "EncounterController"
	new_encounter_controller.world = self.world
	encounter_controller = new_encounter_controller
	add_child(new_encounter_controller)
	
	# validate result
	var result = true
	if !encounter_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the world resources system controller script as object
func _init_resources():
	var new_resource_controller = self.resource_controller_script.new()
	new_resource_controller.name = "ResourceController"
	new_resource_controller.world = self.world
	resource_controller = new_resource_controller
	add_child(new_resource_controller)
	
	# validate result
	var result = true
	if !resource_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the weather system controller script as object
func _init_weather():
	var new_weather_controller = self.weather_controller_script.new()
	new_weather_controller.name = "WeatherController"
	new_weather_controller.world = self.world
	weather_controller = new_weather_controller
	add_child(new_weather_controller)
	
	# validate result
	var result = true
	if !weather_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the terrain system controller script as object
func _init_terrain():
	var new_terrain_controller = self.terrain_controller_script.new()
	new_terrain_controller.name = "TerrainController"
	new_terrain_controller.world = self.world
	terrain_controller = new_terrain_controller
	add_child(new_terrain_controller)
	
	# validate result
	var result = true
	if !terrain_controller:
		result = ERR_DOES_NOT_EXIST
	return result


# initializes the world, grid, tile scenes
func _init_world():
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
	# validate result
	if !utils:
		print("World utils error.")
	
	# init functions array
	var init_controllers = [
		_init_world(),
		_init_terrain(),
		# _init_weather(),
		# _init_resources(),
		# _init_encounters(),
		# _init_player(),
		# _init_time(),
	]
	# run init scrips
	for s in range(init_controllers.size()):
		var result = init_controllers[s]
		# if error initializing...
		if result is Error:
			# print error & pause tree
			print(error_string(result) + " at script " + str(s))
			self.get_tree().paused = true
		# if no errors...
		else:
			# initialization process was valid
			pass


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Initializing world...")
	
	# initialize controller dependencies
	_init_controllers()
	
	print("World initialized.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
