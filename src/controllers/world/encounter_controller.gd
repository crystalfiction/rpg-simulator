extends Controller

# refs
var FileLogger

# components
var encounters = {
	"tile_map": []
}
var init_encounter = {
	"player": null,
	"enemies": [],
	"n_enemies": 0,
}
var encounter_chance: float = 0.33
var n_encounters = 0

var encountering = false
var encounter: Dictionary

# Encounter Generation

## gets r random tiles and returns as an array of objects
func _get_resource_tiles(tiles: Array) -> Array:
	# flatten terrain map
	var tiles_flattened = []
	for x in range(tiles.size()):
		for y in range(tiles[x].size()):
			var t = tiles[x][y]
			tiles_flattened.append(t)
	
	# pick r random tiles with resources
	var tiles_filtered = tiles_flattened.filter(func(t): return t.data.resources.food)
	var r_tiles = tiles_filtered
	
	# validate result
	var result = OK
	if r_tiles.size() == 0:
		# invalid resource data; resources don't exist
		result = ERR_INVALID_PARAMETER
	return [result, r_tiles]

## determines whether or not the parent tile spawns an encounter
## returns an array of enemies, or empty if no encounter spawned
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
			var map_count = self.world.data.terrain.map_count
			# var n_enemies = ceil(map_count / 2.5)
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

	# validate
	var result = OK
	if !tile_map:
		result = ERR_INVALID_DATA
	return [result, tile_map]

# Encounter Initialization

## initializes controller dependencies
## returns result flag and tile_map
func init_controller() -> Array:
	# generate player encounters in world tiles
	var results = _generate_encounters(self.encounters.tile_map)
	var is_OK = results[0]
	var new_tile_map = results[1]

	# validate
	var result = is_OK
	if is_OK != OK:
		result = ERR_INVALID_DATA
	return [result, new_tile_map]

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get FileLogger
	self.FileLogger = $"/root/FileLogger"
	# initialize encounter system
	var results = init_controller()
	var is_OK = results[0]
	var new_tile_map = results[1]
	if is_OK == OK:
		# update resource map
		self.encounters.tile_map = new_tile_map
		# add to terrain data
		self.parent.terrain.encounters = self.encounters
	else:
		# log results if error
		FileLogger.log_message(self , results)

# Encounter Processing

## processes the current encounter and evaluates state
func _process_encounter(current_encounter: Dictionary):
	var enemies = current_encounter.enemies
	var p = current_encounter.player
	if enemies.any(func(e): return !is_instance_valid(e) || e == null) || (
		!is_instance_valid(p)
	):
		# flag encounter done
		self.encountering = false
		return
		
	FileLogger.log_message(self , "Processing encounter...")
	## FIXME: with multiple enemies, player attacks for every enemy attack per encounter
	# for each player,
	# for each enemy,
	if enemies.size() > 1:
		for e in enemies:
			# evaluate combat
			p.data.controller.evaluate_combat(p, e)
			e.data.controller.evaluate_combat(e, p)
			current_encounter.n_enemies = enemies.size()
	else:
		# if either entity is null, stop encounter and initialize data
		var e = enemies.front()
		if e == null:
			# flag encounter done
			self.encountering = false
			current_encounter = self.init_encounter
		# if both entities good,
		else:
			# evaluate combat
			p.data.controller.evaluate_combat(p, e)
			e.data.controller.evaluate_combat(e, p)
			current_encounter.n_enemies = enemies.size()

## handles encounter-level data processing
func _process_cycle():
	var time_controller = self.world.data.controller.time_controller
	if time_controller.cycling && self.world:
		if self.encountering:
			_process_encounter(self.encounter)

## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_process_cycle()
