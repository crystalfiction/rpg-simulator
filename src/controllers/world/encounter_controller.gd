extends Controller

# state
var encountering = null
# var cycle_complete = false
# components
var encounters_map: Array
var encounter_tiles = []
var n_encounters = 0
var encounter_ratio = 0.33

# gets r random tiles and returns as an array of objects
func _get_random_tiles(tiles: Array, r: int):
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
	var result = true
	if r_tiles.size() > 0:
		result = r_tiles
	else:
		result = false
	return result


# generates player encounters for the given terrain map
func _generate_encounters(tile_map: Array):
	# get world resources
	var world_resources = self.world.data.resources.size()
	# update n_encounters to 50% of resource count
	self.n_encounters = floor(world_resources * encounter_ratio)
	# get n random tiles according to encounter count
	var r_tiles = _get_random_tiles(tile_map, self.n_encounters)
	# break if could not find random tiles
	if !r_tiles:
		print("Error finding encounter tiles")
		return
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
				# update encounter tiles array for world ref
				self.encounter_tiles.append(t)
	
	# return new terrain
	if tile_map:
		return tile_map
	return ERR_DOES_NOT_EXIST


# handles encounter-level data processing
# called by player_controller
func process_encounter(p: Player, t: Tile):
	print("Processing encounter...")

	## after encounter
	# add encounter to player encounters array
	p.data.encounters.done += 1
	p.data.actions.action.encountered = true
	
	# move encounter to done array
	## TODO: consider a solution for multiple encounters on the same tile
	var first_encounter = t.data.encounters.ready.pop_front()
	t.data.encounters.done.append(first_encounter)

	print("Encounter complete.")


# initializes controller dependencies
func _init_controller():
	# generate player encounters in world tiles
	var result = _generate_encounters(self.world.data.terrain.tile_map)
	# validate result
	if result:
		return result
	return ERR_INVALID_DATA


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# initialize the controller if resources initialized
	var world_controller = self.world.data.controller
	if world_controller.resource_controller.resources_optimized:
		var result = _init_controller()
		if result is Error:
			# did not initialize
			print(result)
		else:
			# update world tile_map if valid
			self.world.data.terrain.tile_map = result
