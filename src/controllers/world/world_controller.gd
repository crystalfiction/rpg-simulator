extends Controller

# script references
var terrain_controller_script: Resource = preload("res://src/controllers/world/terrain_controller.gd")
var player_controller_script: Resource = preload("res://src/controllers/entities/player/player_controller.gd")
var enemy_controller_script: Resource = preload("res://src/controllers/entities/enemy/enemy_controller.gd")
# scene references
var world_scene: Resource = preload("res://src/entities/world/world.tscn")
var time_controller_scene: Resource = preload("res://src/controllers/world/time_controller.tscn")
var ui_scene: Resource = preload("res://src/controllers/ui/ui_controller.tscn")
# controllers
var ui_controller: Control
var terrain_controller: Controller
var time_controller: Node2D
var player_controller: Controller
var enemy_controller: Controller
# components
var uid_ref = 0


# Controller Initialization 

## initializes the ui controller scene
func _init_ui() -> Control:
	var new_ui = ui_scene.instantiate()
	new_ui.name = "UiController"
	new_ui.world = self.world
	# assign to controller reference before wiring logger
	self.ui_controller = new_ui
	if self.FileLogger:
		self.FileLogger.ui_controller = self.ui_controller
	add_child(new_ui)
	return new_ui

# initializes the enemy system controller script as object
func _init_enemy_controller() -> Controller:
	var new_enemy_controller = self.enemy_controller_script.new()
	new_enemy_controller.name = "EnemyController"
	new_enemy_controller.world = self.world
	new_enemy_controller.parent = self
	# assign controller reference early
	self.enemy_controller = new_enemy_controller
	add_child(new_enemy_controller)
	return new_enemy_controller

## initializes the player system controller script as object
func _init_player_controller() -> Controller:
	var new_player_controller = self.player_controller_script.new()
	new_player_controller.name = "PlayerController"
	new_player_controller.world = self.world
	new_player_controller.parent = self
	# assign controller reference early
	self.player_controller = new_player_controller
	add_child(new_player_controller)
	return new_player_controller

## initializes the time system controller script as object
func _init_time_controller() -> Controller:
	var new_time_controller = self.time_controller_scene.instantiate()
	new_time_controller.name = "TimeController"
	new_time_controller.world = self.world
	new_time_controller.parent = self
	# assign controller reference early
	self.time_controller = new_time_controller
	add_child(new_time_controller)
	return new_time_controller

## initializes the terrain system controller script as object
func _init_terrain_controller() -> Controller:
	var new_terrain_controller = self.terrain_controller_script.new()
	new_terrain_controller.name = "TerrainController"
	new_terrain_controller.world = self.world
	new_terrain_controller.parent = self
	# assign controller reference early
	self.terrain_controller = new_terrain_controller
	add_child(new_terrain_controller)
	return new_terrain_controller


# World Initialization

## initializes the world entity as scene
func _init_world_scene() -> Sprite2D:
	var new_world: Sprite2D = World.new().init_scene()
	new_world.name = "World"
	var screen_size = get_tree().root.size
	new_world.texture.width = screen_size.x
	new_world.texture.height = screen_size.y
	add_child(new_world)
	return new_world

## initializes controller dependencies
func _init_controllers() -> void:
	# init world entity
	var new_world: Sprite2D = _init_world_scene()
	new_world.data.controller = self
	self.world = new_world

	# terrain
	var new_terrain_controller = _init_terrain_controller()
	self.terrain_controller = new_terrain_controller

	# players
	var new_player_controller = _init_player_controller()
	self.player_controller = new_player_controller

	# enemies
	var new_enemy_controller = _init_enemy_controller()
	self.enemy_controller = new_enemy_controller
	
	# time
	var new_time_controller = _init_time_controller()
	self.time_controller = new_time_controller

	# ui
	var new_ui_controller = _init_ui()
	self.ui_controller = new_ui_controller


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"
	
	FileLogger.log_message(self, "::INITIALIZING::")
	
	# initialize controller dependencies
	_init_controllers()
	
	FileLogger.log_message(self, "::INITIALIZED::")


# World Processing

## accepts current world entity,
## validates world data and returns result flag
func _process_cycle(current_world: Sprite2D):
	# if time_controller is cycling (game is active),
	if self.time_controller:
		if self.time_controller.cycling:
			# if world is valid,
			if is_instance_valid(current_world):
				## process world state conditions
				# if player_controller exists, but player is invalid
				if player_controller && !self.world.data.player:
					# reload game if only Map 1,
					if current_world.data.terrain.data.map_count == 1:
						FileLogger.log_message(self,
							"Player died on Map 1, reloading world..."
						)
						get_tree().reload_current_scene()
					else:
						# otherwise end game
						FileLogger.log_message(self,
							"Player died on Map " + str(current_world.data.terrain.data.map_count)
						)
						get_tree().quit()

			# if world invalid,
			else:
				# world is not valid,
				FileLogger.log_message(self, "World is invalid, ending game.")
				# quit game, world invalid
				get_tree().quit()

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# process cycle
	_process_cycle(self.world)
