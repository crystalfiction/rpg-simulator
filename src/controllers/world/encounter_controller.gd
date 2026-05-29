extends Controller

# components
var encounters = {
	"tile_map": [],
	"count": 0
}
var encounter_ratio = 0.33
var n_encounters = 0

# gets r random tiles and returns as an array of objects
func _get_random_tiles(tiles: Array, r: int) -> Array:
	# flatten terrain map
	var tiles_flattened = []
	for x in range(tiles.size()):
		for y in range(tiles[x].size()):
			var t = tiles[x][y]
			tiles_flattened.append(t)
	
	# pick r random tiles with resources
	var tiles_filtered = tiles_flattened.filter(func(t): return t.data.resources.food)
	var r_tiles = []
	for n in range(r):
		r_tiles.append(tiles_filtered.pick_random())
	
	# validate result
	var result = OK
	if r_tiles.size() == 0:
		# invalid resource data; resources don't exist
		result = ERR_INVALID_PARAMETER
	return [result, r_tiles]


# handles encounter-level data processing
func process_encounter(p: Player, t: Tile) -> void:
	## encounter start
	print("Something encountered!")
	# spawn enemies
	var world_controller = self.world.data.controller
	# spawn enemies according to map count
	var map_count = self.world.data.terrain.map_count
	world_controller.enemy_controller.spawn_enemies(t, map_count)
	
	# TODO: process interaction between player + enemies
	var enemies = t.data.enemies.ready

	## after encounter
	# add encounter to player encounters array
	p.data.encounters.done += 1
	
	# move encounter to done array
	## TODO: consider a solution for multiple encounters on the same tile
	var first_encounter = t.data.encounters.ready.pop_front()
	t.data.encounters.done.append(first_encounter)

	print("Encounter complete.")


# generates player encounters for the given terrain map
func _generate_encounters(tile_map: Array) -> Array:
	# get world resources
	var r_available = self.parent.resource_controller.resources.count
	# update n_encounters to 50% of resource count
	self.n_encounters = floor(r_available * encounter_ratio)
	# get n random tiles according to encounter count
	var results = _get_random_tiles(tile_map, self.n_encounters)
	var is_OK = results[0]
	var r_tiles = results[1]
	# break if could not find random tiles
	if is_OK != OK:
		print("Error finding encounter tiles")
		# return error and current tile_map
		return [is_OK, tile_map]
	# loop through terrain and place encounters n_times
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# get current tile
			var t = tile_map[x][y]
			# initialize encounters struct
			t.data.encounters = {
				"ready": [],
				"done": []
			}
			# if the current tile is in r_tiles
			if t in r_tiles:
				# place encounter
				## TODO: elaborate on encounter data
				t.data.encounters.ready.append([ self ])
				self.encounters.count += 1
	
	# log result
	print(
		"encounters_generated: " + str(self.encounters.count)
	)

	# validate
	var result = OK
	if !tile_map:
		result = ERR_INVALID_DATA
	return [result, tile_map]


# initializes controller dependencies
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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
		print(results)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
