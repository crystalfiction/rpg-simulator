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
func _generate_encounters(terrain: Array):
	# get world resources
	var world_resources = self.world.data.tiles.data.resources.size()
	# update n_encounters to 50% of resource count
	self.n_encounters = floor(world_resources * encounter_ratio)
	# get n random tiles according to encounter count
	var r_tiles = _get_random_tiles(terrain, self.n_encounters)
	# break if could not find random tiles
	if !r_tiles:
		print("Error finding encounter tiles")
		return
		
	# loop through terrain and place encounters n_times
	var new_terrain = []
	for x in range(terrain.size()):
		new_terrain.append([])
		for y in range(terrain[x].size()):
			# get current tile
			var t = terrain[x][y]
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
			
			# append to new terrain array
			new_terrain[x].append(t)
	
	# return new terrain
	if new_terrain:
		return new_terrain
	return ERR_DOES_NOT_EXIST


# handles encounter-level data processing
# called by player_controller
func process_encounter(p: Player, t: Tile):
	print("Processing encounter...")

	# flag encounter_controller as encountering
	self.encountering = true

	# do encounter

	# unflag encountering
	self.encountering = false

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
	var result = _generate_encounters(self.world.data.tiles.objs)
	# validate result
	if result:
		return result
	return ERR_INVALID_DATA


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# initialize the controller
	var result = _init_controller()
	if result:
		# done
		pass
	else:
		# did not initialize
		print(result)
