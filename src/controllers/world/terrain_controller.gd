extends Controller

# refs
var weather_controller_script = preload("res://src/controllers/world/weather_controller.gd")
var resource_controller_script = preload("res://src/controllers/world/resource_controller.gd")
var encounter_controller_script = preload("res://src/controllers/world/encounter_controller.gd")

# controllers
var weather_controller: Controller
var resource_controller: Controller
var encounter_controller: Controller

# components
var grid_dimensions: Vector2i
var grid_scale = Vector2i(36, 36)

var terrain_iterations: int

var soil_density_min = 0.22 # min increased to account for erosion
var soil_density_max = 1.00
var soil_variance = 0.55
var soil_texture_factor = 0.33


# Terrain Helpers

## updates world terrain reference when reference data changed
func _handle_terrain(curr_terrain: Terrain):
	# update world terrain to current terrain
	self.world.data.terrain = curr_terrain


# Terrain Simulation

## calculates new soil values for the passed tile,  
## factors in neighbor data from the passed tile map,
## returns array of passed tile and its metrics
func _calculate_soil(tile: Tile, terrain_map: Array) -> Array:
	# define metrics
	var n_avg_dist = 0
	var n_textures = []
	var n_avg_density = 0
	var n_count = 0
	var neighbors = self.Utils.get_neighbors(tile, terrain_map)
	var s = tile.data.terrain.density
	# get neighbor data
	for n in neighbors:
		# get distance to neighbor
		var n_distance = n.data.terrain.density - s
		# update metrics
		n_avg_dist += n_distance
		n_avg_density += n.data.terrain.density
		n_count += 1
		n_textures.append(n.data.terrain.texture)
		
	# calculate neighbor avg
	n_avg_density /= n_count
	n_avg_dist /= n_count
	var avg_texture = self.Utils.common_string(n_textures)
	
	# lerp soil value towards total avg distance to each neighbor
	var d_scalar = n_avg_dist
	var t_scalar = tile.data.terrain[avg_texture] - s
	
	## apply d_scalar to soil density
	## representing tendency towards neighboring soil densities
	var new_s_neighbors = clamp(
		lerp(
			(s), (s + d_scalar), (1 - soil_variance)
		), soil_density_min, soil_density_max
	)
	## apply t_scalar to soil density
	## representing tendency towards soil texture classification
	new_s_neighbors = clamp(
		lerp(
			(new_s_neighbors), (new_s_neighbors + t_scalar), soil_texture_factor * (1 - soil_variance)
		), soil_density_min, soil_density_max
	)
	tile.data.terrain.density = new_s_neighbors
		
	# return the passed entity with updated soil value
	return [tile, n_avg_density, n_avg_dist, avg_texture]

## normalizes soil values to soil_density_min, soil_density_max
## returns normalized terrain tile_map
func _normalize_soil(
	tile_map: Array,
	sd_min: float = soil_density_min,
	sd_max: float = soil_density_max
) -> Array:
	var min_s = INF
	var max_s = - INF
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			min_s = min(min_s, tile_map[x][y].data.terrain.density)
			max_s = max(max_s, tile_map[x][y].data.terrain.density)
	
	var range_val = max_s - min_s
	var avg = 0
	var count = 0
	if range_val == 0: return tile_map
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# remap soil densities to soil_density_min, soil_density_max
			tile_map[x][y].data.terrain.density = remap(
				tile_map[x][y].data.terrain.density,
				min_s, max_s,
				sd_min, sd_max)
			# update metrics
			avg += tile_map[x][y].data.terrain.density
			count += 1
	
	avg = avg / count
	return [tile_map, avg]

## optimizes soil data in the world tile map,
## returns result flag
func _optimize_soil(terrain: Terrain) -> Array:
	# loop through terrain map
	var avg_density = 0
	var avg_dist_sq = 0
	var avg_textures = []
	var count = 0
	var tile_map = terrain.data.tile_map
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# do something with soil value
			var t = tile_map[x][y]
			var new_t = _calculate_soil(t, tile_map)
			# update tile_map
			tile_map[x][y] = new_t[0]
			avg_density += new_t[1]
			avg_dist_sq += new_t[2] ** 2
			avg_textures.append(new_t[3])
			count += 1

	# apply normalization to terrain soil density
	# according to biome if one exists
	var norm_soil = _normalize_soil(tile_map)
	tile_map = norm_soil[0]
	avg_density = norm_soil[1]
	
	# update metrics
	self.terrain_iterations += 1
	avg_dist_sq = avg_dist_sq * 100 / count
	var total_avg_texture = self.Utils.common_string(avg_textures)
	terrain.data.metrics = {
		"avg_density": snapped(avg_density, 0.001),
		"avg_texture": total_avg_texture
	}

	# define completion threshold
	var threshold = soil_variance / 1.5
	var condition = (avg_dist_sq <= threshold)
	
	# determine if conditions met
	var result = false
	if condition:
		# conditions met
		# only print last iteration
		var msg = (
			"iterations: " + str(terrain_iterations) + " | " +
			"avg_density: " + str(snapped(avg_density, 0.0001)) + " | " +
			"avg_dist_sq " + str(snapped(avg_dist_sq, 0.0001)) + " | " +
			"threshold " + str(snapped(threshold, 0.0001))

		)
		FileLogger.log_message(self , msg)
		# stop optimizing,
		result = true
	
	# reset metrics
	count = 0
	avg_density = 0
	avg_dist_sq = 0

	# true if valid
	return [result, terrain]

## optimizes terrain in the world tile map
## returns optimized flag
func _optimize_terrain(terrain: Terrain) -> Terrain:
	FileLogger.log_message(self , "Optimizing terrain...")

	# run terrain optimization cycle
	var optimized = false
	while !optimized:
		# try to optimize soil
		var result = _optimize_soil(terrain)
		# test result
		var is_OK = result[0]
		if is_OK:
			# terrain is optimized and valid
			optimized = true
			terrain = result[1]
			terrain.data.metrics.optimized = true
			terrain.data.metrics.iterations = self.terrain_iterations
			# reset metrics
			self.terrain_iterations = 0
		else:
			# terrain is not optimized, 
			# update loop flag in case of null errors
			optimized = is_OK
	
	# return optimization results
	return terrain

## generates new terrain object and saves to world.data.terrain
## called when player has completed all conditions on a map
func _generate_terrain(curr_terrain: Terrain) -> void:
	# TODO: add a way to reset terrain data without breaking dependencies
	# reuse existing Terrain obj
	var new_terrain = curr_terrain

	# reinitialize soil
	new_terrain = _init_soil(new_terrain, curr_terrain.data.biome)

	# optimize terrain
	new_terrain = _optimize_terrain(new_terrain)

	# add callback to terrain for calling on data change
	new_terrain.data.on_change = _handle_terrain.bind(new_terrain)

	# generate weather on terrain
	self.weather_controller.terrain = new_terrain
	self.weather_controller.init_controller()
	# generate resources after weather
	self.resource_controller.terrain = new_terrain
	self.resource_controller.init_controller()
	# generate encounters on terrain
	self.encounter_controller.terrain = new_terrain
	self.encounter_controller.init_controller()

	# log update
	FileLogger.log_message(self , "Map " + str(new_terrain.data.map_count) + " generated.")
	

	# update world terrain to new terrain
	self.world.data.terrain = new_terrain

	# unflag map_complete
	self.world.data.terrain.data.map_complete = false

# Terrain Initialization

## accepts a terrain object and
## returns a terrain object with initialized soil values in tile_map
func _init_soil(terrain: Terrain, biome: Biome = null) -> Terrain:
	var tile_map = terrain.data.tile_map
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			var t = tile_map[x][y]
			# initialize soil data
			if biome == null:
				var s_types = 3
				var sand = randf_range(self.soil_density_min, self.soil_density_max)
				var silt = randf_range(self.soil_density_min, self.soil_density_max)
				var clay = randf_range(self.soil_density_min, self.soil_density_max)
				var density = (sand + clay + silt)
				t.data.terrain = {
					"sand": sand / s_types,
					"silt": silt / s_types,
					"clay": clay / s_types,
					"density": density / s_types
				}
				# get verbose soil texture
				t.data.terrain.texture = self.Utils.get_soil_texture(t)
			
			# biome passed,
			else:
				# update tile data according to biome
				var s_types = 3
				var sand = randf_range(biome.data.ranges.density[0], biome.data.ranges.density[1])
				var silt = randf_range(biome.data.ranges.density[0], biome.data.ranges.density[1])
				var clay = randf_range(biome.data.ranges.density[0], biome.data.ranges.density[1])
				var density = (sand + clay + silt)
				t.data.terrain = {
					"sand": sand / s_types,
					"silt": silt / s_types,
					"clay": clay / s_types,
					"density": density / s_types
				}
				# get verbose soil texture
				t.data.terrain.texture = self.Utils.get_soil_texture(t)
			
	# update terrain
	terrain.data.tile_map = tile_map
	terrain.data.map_count += 1

	return terrain
	
## initializes a single tile given a position and world grid index
## returns the new tile object
func _init_grid_tile(pos: Vector2i, grid_idx: Vector2i) -> Tile:
	var uid_ref = self.world.data.controller.uid_ref
	var new_tile = Tile.new().init_scene()
	new_tile.data.world = self.world
	new_tile.data.uid = uid_ref
	new_tile.data.grid_idx = grid_idx
	new_tile.name = "tile_" + str(new_tile.data.uid)
	new_tile.position = self.Utils.grid_to_world(
		pos, self.grid_scale)
	
	# set the texture dimensions according to grid scale
	new_tile.texture.width = grid_scale.x
	new_tile.texture.height = grid_scale.y
	
	# increment the uid_ref
	uid_ref += 1
	
	return new_tile

## initializes the world tiles using the passed terrain
## returns nested array of new tiles according to grid index
func _init_grid_tiles(terrain: Terrain) -> Array:
	# loop through world grid and create tile at each step
	var new_tile_map = []
	var grid = terrain.data.grid
	for x in range(grid.size()):
		new_tile_map.append([])
		for y in range(grid[x].size()):
			# create a new tile with the given position
			var new_tile = _init_grid_tile(
				Vector2i(grid[x][y].x, grid[x][y].y),
				Vector2i(x, y))
			# add new tile object as child of Terrain
			terrain.add_child(new_tile)
			# push new tile to array
			new_tile_map[x].append(new_tile)
	
	return new_tile_map

## initializes the world grid and returns a nested array of 
## screen positions organized by grid steps, grid scale
func _init_grid(scale: Vector2i) -> Array:
	# get screen dimensions
	var screen_size = get_tree().root.get_viewport().size
	# Calculate how many tiles fit on the screen
	var cols = floor(screen_size.x / scale.x)
	var rows = floor(screen_size.y / scale.y)
	var scaled_dimensions = Vector2i(cols, rows)
	self.grid_dimensions = scaled_dimensions
	
	# create new grid
	var new_grid = []
	for x in range(self.grid_dimensions.x):
		new_grid.append([])
		for y in range(self.grid_dimensions.y):
			# append grid coordinates to current row, col
			new_grid[x].append(Vector2i(x, y))
	
	return new_grid

## initializes the encounters system controller script as object,
## returns error flag
func _init_encounters(terrain: Terrain) -> Controller:
	var new_encounter_controller = self.encounter_controller_script.new()
	new_encounter_controller.name = "EncounterController"
	new_encounter_controller.world = self.world
	new_encounter_controller.parent = self
	new_encounter_controller.terrain = terrain
	add_child(new_encounter_controller)
	return new_encounter_controller

## initializes the world resources system controller script as object,
## returns error flag
func _init_resources(terrain: Terrain) -> Controller:
	var new_resource_controller = self.resource_controller_script.new()
	new_resource_controller.name = "ResourceController"
	new_resource_controller.world = self.world
	new_resource_controller.parent = self
	new_resource_controller.terrain = terrain
	add_child(new_resource_controller)
	return new_resource_controller

## initializes the weather system controller script as object,
## returns error flag
func _init_weather(terrain: Terrain) -> Controller:
	var new_weather_controller = self.weather_controller_script.new()
	new_weather_controller.name = "WeatherController"
	new_weather_controller.world = self.world
	new_weather_controller.parent = self
	new_weather_controller.terrain = terrain
	add_child(new_weather_controller)
	return new_weather_controller

## initializes the world terrain with init terrain data,
## returns error flag
func _init_terrain() -> Terrain:
	# create new Terrain obj
	var new_terrain = Terrain.new()

	# initialize world grid
	var new_grid = _init_grid(self.grid_scale)
	new_terrain.data.grid = new_grid
	
	# initialize world tiles
	var new_tile_map = _init_grid_tiles(new_terrain)
	new_terrain.data.tile_map = new_tile_map
	
	# initialize soil data in terrain
	new_terrain = _init_soil(new_terrain)

	# add callback to terrain for calling on data change
	new_terrain.data.on_change = _handle_terrain.bind(new_terrain)

	return new_terrain

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# initialize terrain entity
	var new_terrain = _init_terrain()
	# optimize terrain
	new_terrain = _optimize_terrain(new_terrain)

	# initialize terrain weather controller
	var new_weather_controller = _init_weather(new_terrain)
	self.weather_controller = new_weather_controller

	# initialize terrain resource controller
	var new_resource_controller = _init_resources(new_terrain)
	self.resource_controller = new_resource_controller

	# initialize terrain encounter controller
	var new_encounter_controller = _init_encounters(new_terrain)
	self.encounter_controller = new_encounter_controller

	# determine biome
	if not "weather" in new_terrain.data:
		while new_terrain.data.weather.is_empty():
			pass
	
	new_terrain.data.biome = new_terrain.get_terrain_biome()

	# update world terrain to new terrain
	self.world.data.terrain = new_terrain
	# add terrain to world tree
	self.world.add_child(new_terrain)


# Terrain Processing

## processes the controller's time cycle
func _process_cycle(curr_world: Sprite2D):
	## General terrain cycle logic
	# ignore time cycle
	if curr_world:
		# if no resources left in terrain,
		var current_terrain = curr_world.data.terrain
		var resources = self.Utils.get_resources(current_terrain.data.tile_map)
		var is_resources = (
			not resources.is_empty() ||
			not curr_world.data.terrain.data.resources.count <= 0
		)
		if !is_resources:
			# flag terrain map complete
			curr_world.data.terrain.data.map_complete = true
			FileLogger.log_message(self , "No resources found, initializing new map.")
		
		# check map completion regardless of time cycle state
		if curr_world.data.terrain.data.map_complete:
			var curr_terrain = curr_world.data.terrain
			# initialize a new terrain
			_generate_terrain(curr_terrain)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# process terrain cycle
	_process_cycle(self.world)
