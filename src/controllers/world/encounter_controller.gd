extends Controller

# refs

# components
var terrain: Terrain
var init_encounter = {
	"cycle": 0,
	"player": null,
	"enemies": [],
	"n_enemies": 0,
}
var encounter_chance: float = 0.50
var encounter_count: int = 0

var encountering = false
var encounter: Dictionary

# Encounter Generation

## determines whether or not the parent tile spawns an encounter
## returns true or false depending on whether encounter was spawned
func _spawn_encounter(p: Player, tile: Tile) -> bool:
	var enemy_controller = self.world.data.controller.enemy_controller
	var new_enemies = []
	var current_encounter = self.init_encounter # initialize encounter data
	# if tile has resources,
	if tile.data.resources.food:
		# generate random number r
		var r = randf_range(0, 1)
		if r <= self.encounter_chance:
			# encounter spawned,
			# spawn enemies,
			var _map_count = self.terrain.data.map_count
			# var n_enemies = ceil(_map_count / 2.5)
			new_enemies = enemy_controller.spawn_enemies(1) # only spawn 1 enemy
			# prepare new encounter for processing
			current_encounter.player = p
			current_encounter.enemies = new_enemies
			current_encounter.n_enemies = new_enemies.size()
		
			self.encounter = current_encounter
			self.encountering = true
			var msg = (
				str(current_encounter.n_enemies) + " enemies appear!"
				if current_encounter.n_enemies > 1
				else str(current_encounter.n_enemies) + " enemy appears!"
			)
			FileLogger.log_message(self ,
				msg
			)

	return self.encountering

## generates player encounters for the given terrain map
func _generate_encounters(tile_map: Array) -> Array:
	# loop through terrain and place encounters n_times
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# get current tile
			var t = tile_map[x][y]
			# initialize encounters data in tile
			t.data.encounters = {
				# callable returns an array of enemies or empty array
				"spawn": _spawn_encounter.bind(t)
			}

	return tile_map


# Encounter Initialization

## initializes controller dependencies
## returns result flag and tile_map
func init_controller() -> void:
	# generate player encounters in world tiles
	var new_tile_map = _generate_encounters(self.terrain.data.tile_map)
	# update terrain
	self.terrain.data.tile_map = new_tile_map
	self.terrain.data.on_change.call()

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# initialize encounter system
	init_controller()
	

# Encounter Processing

## processes the current encounter and evaluates state
func _process_encounter(current_encounter: Dictionary):
	var enemies = current_encounter.enemies
	var p = current_encounter.player
	if enemies.all(func(e): return !is_instance_valid(e) || e == null) || (
		!is_instance_valid(p)
	):
		# flag encounter done
		self.encountering = false
		return
	
	# loop through and delete any enemies that are invalid
	# until encounter done
	for e in enemies:
		if e == null || !is_instance_valid(e):
			enemies.erase(e)

	# update enemy count if changed
	current_encounter.n_enemies = enemies.size()
	FileLogger.log_message(self , "Processing encounter...")

## handles encounter-level data processing
func _process_cycle():
	var time_controller = self.world.data.controller.time_controller
	if time_controller:
		if time_controller.cycling && self.world:
			if self.encountering:
				_process_encounter(self.encounter)

## Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_cycle()
