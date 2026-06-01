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
func _spawn_encounter(p: Player, tile: Tile) -> Dictionary:
	var enemy_controller = self.world.data.controller.enemy_controller
	var new_enemies = []
	var current_encounter = self.init_encounter # initialize encounter data
	# if tile has resources,
	if tile.data.resources.food:
		# generate random number r
		var r = randf_range(0, 1)
		if r <= self.encounter_chance:
			# encounter spawned,
			var map_count = self.world.data.terrain.map_count
			new_enemies = enemy_controller.spawn_enemies(map_count)
			# prepare new encounter for processing
			current_encounter.player = p
			current_encounter.enemies = new_enemies
			current_encounter.n_enemies = new_enemies.size()
			self.encounter = current_encounter
			self.encountering = true
			FileLogger.log_message("Encounter spawned!")

	return current_encounter


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


## initializes controller dependencies
func _init_controller() -> Array:
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
	var results = _init_controller()
	var is_OK = results[0]
	var new_tile_map = results[1]
	if is_OK == OK:
		# update resource map
		self.encounters.tile_map = new_tile_map
		# add to terrain data
		self.parent.terrain.encounters = self.encounters
	else:
		# log results if error
		FileLogger.log_message(results)


func _process_encounter(current_encounter: Dictionary):
	FileLogger.log_message("Processing encounter...")
	var enemies = current_encounter.enemies
	var p = current_encounter.player
	# for each player,
	# for each enemy,
	if enemies.size() > 1:
		for e in enemies:
			# if either entity is null, stop encounter and initialize data
			if e == null || p == null:
				# flag encounter done
				self.encountering = false
				current_encounter = self.init_encounter
			# if both entities good,
			else:
				# evaluate combat
				p.data.controller.evaluate_combat(p, e)
				e.data.controller.evaluate_combat(e, p)
	else:
		# if either entity is null, stop encounter and initialize data
		var e = enemies.front()
		if e == null || p == null:
			# flag encounter done
			self.encountering = false
			current_encounter = self.init_encounter
		# if both entities good,
		else:
			# evaluate combat
			p.data.controller.evaluate_combat(p, e)
			e.data.controller.evaluate_combat(e, p)

	# return updated encounter
	return current_encounter


## handles encounter-level data processing
func _process_cycle():
	var time_controller = self.world.data.controller.time_controller
	if time_controller.cycling:
		if self.encountering:
			_process_encounter(self.encounter)


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_process_cycle()
