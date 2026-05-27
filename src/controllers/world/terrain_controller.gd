extends Controller

# refs
var tile_scene = preload("res://src/entities/world/tile.tscn")
# grid
var grid_dimensions: Vector2i
var grid_scale = Vector2i(36, 36)
# terrain
var terrain = {
	"grid": [],
	"tile_map": [],
}
var terrain_iterations: int
var terrain_optimized = null
# soil
var soil_density_min = 0.11
var soil_density_max = 1.00
var soil_variance = 0.66
var soil_texture_factor = 0.44


# normalize soil values to soil_density_min, soil_density_max
func _normalize_soil(
	new_terrain: Array,
	sd_min: float = soil_density_min,
	sd_max: float = soil_density_max
):
	var min_s = INF
	var max_s = - INF
	for x in range(new_terrain.size()):
		for y in range(new_terrain[x].size()):
			min_s = min(min_s, new_terrain[x][y].data.terrain.density)
			max_s = max(max_s, new_terrain[x][y].data.terrain.density)
	
	var range_val = max_s - min_s
	var avg = 0
	var count = 0
	if range_val == 0: return new_terrain
	for x in range(new_terrain.size()):
		for y in range(new_terrain[x].size()):
			# remap soil densities to soil_density_min, soil_density_max
			new_terrain[x][y].data.terrain.density = remap(
				new_terrain[x][y].data.terrain.density,
				min_s, max_s,
				sd_min, sd_max)
			# update metrics
			avg += new_terrain[x][y].data.terrain.density
			count += 1
	
	avg = avg / count
	return [new_terrain, avg]

# calculates new soil values for the passed tile, factoring in 
# neighbor data from the passed tile map
func _calculate_soil(tile: Tile, terrain_map: Array):
	# define metrics
	var n_avg_dist = 0
	var n_textures = []
	var n_avg_density = 0
	var n_count = 0
	var neighbors = self.world.data.controller.utils.get_neighbors(tile, terrain_map)
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
	var avg_texture = self.world.data.controller.utils.common_string(n_textures)
	
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


# optimizes soil data in the world tile map
func _optimize_soil(terrain_map: Array):
	# loop through terrain map
	var avg_density = 0
	var avg_dist_sq = 0
	var avg_textures = []
	var count = 0
	for x in range(terrain_map.size()):
		for y in range(terrain_map[x].size()):
			# do something with soil value
			var t = terrain_map[x][y]
			var new_t = _calculate_soil(t, terrain_map)
			# update terrain_map
			terrain_map[x][y] = new_t[0]
			avg_density += new_t[1]
			avg_dist_sq += new_t[2] ** 2
			avg_textures.append(new_t[3])
			count += 1

	# determine if more optimization necessary
	# normalize terrain
	var new_terrain = _normalize_soil(terrain_map)
	terrain_map = new_terrain[0]
	
	# update metrics
	terrain_iterations += 1
	avg_density = new_terrain[1]
	avg_dist_sq = avg_dist_sq * 100 / count
	var total_avg_texture = self.world.data.controller.utils.common_string(avg_textures)

	# define completion threshold
	var threshold = soil_variance / 1.5
	var condition = (avg_dist_sq <= threshold)
	
	# determine if conditions met
	var result = false
	if condition:
		# conditions met
		# only print last iteration
		print(
			"iterations: " + str(terrain_iterations) + " | ",
			"tiles: " + str(count) + " | ",
			"avg_density: " + str(snapped(avg_density, 0.0001)) + " | ",
			"avg_dist_sq " + str(snapped(avg_dist_sq, 0.0001)) + " | ",
			"threshold " + str(snapped(threshold, 0.0001))
		)
		# flag result
		result = true
	
	# reset metrics
	count = 0
	avg_density = 0
	avg_dist_sq = 0

	# true if valid
	return result


# optimizes terrain in the world tile map
func _optimize_terrain(terrain_map: Array):
	print("Optimizing terrain...")
	
	# run terrain optimization cycle
	var optimized = false
	while !optimized:
		# try to optimize soil
		var result = _optimize_soil(terrain_map)
		# test result
		if result:
			# terrain is optimized and valid
			optimized = true
			terrain_optimized = optimized
			# reset metrics
			terrain_iterations = 0
		else:
			# terrain is not optimized, return result
			optimized = result
	
	# return optimization results
	return optimized


# accepts a tile_map and returns an array mapped with terrain values
func _init_terrain(tile_map: Array):
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			var t = tile_map[x][y]
			# initialize soil data
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
			t.data.terrain.texture = self.world.data.controller.utils.get_soil_texture(t)
	
	return tile_map
	

# initializes a single tile given a position and world grid index
func _init_grid_tile(pos: Vector2i, grid_idx: Vector2i):
	var uid_ref = self.world.data.controller.uid_ref
	var new_tile = tile_scene.instantiate()
	# set tile data
	new_tile.world = self.world
	new_tile.data.uid = uid_ref
	new_tile.data.grid_idx = grid_idx
	new_tile.name = "tile_" + str(new_tile.data.uid)
	new_tile.position = self.world.data.controller.utils.grid_to_world(
		pos, self.grid_scale)
	
	# set the texture dimensions according to grid scale
	new_tile.texture.width = grid_scale.x
	new_tile.texture.height = grid_scale.y
	
	# increment the uid_ref
	uid_ref += 1
	
	# validate result if tiles valid
	var result = false
	if new_tile:
		result = new_tile
	
	# return result
	return result


# initializes the world tiles using the passed grid array
# returns nested array of new tiles according to grid index
func _init_grid_tiles(grid: Array):
	# loop through world grid and create tile at each step
	var new_tiles = []
	for x in range(grid.size()):
		new_tiles.append([])
		for y in range(grid[x].size()):
			# create a new tile with the given position
			var new_tile = _init_grid_tile(
				Vector2i(grid[x][y].x, grid[x][y].y),
				Vector2i(x, y))
			# add new tile object as child of world object
			self.world.add_child(new_tile)
			# push new tile to array
			new_tiles[x].append(new_tile)
	
	# validate result if tiles valid
	var result = new_tiles
	if !new_tiles:
		result = false
	
	# return result
	return result


# initializes the world grid and returns a nested array of 
# screen positions organized by grid steps, grid scale
func _init_grid(scale: Vector2i):
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
	
	# validate result if grid valid
	var result = new_grid
	if !new_grid:
		result = false
	
	# return result
	return result


# initializes the world terrain_map with init terrain data
func _init_controller():
	# initialize world grid
	var new_grid = _init_grid(self.grid_scale)
	self.terrain.grid = new_grid
	
	# initialize world tiles
	var new_grid_tiles = _init_grid_tiles(self.terrain.grid)
	self.terrain.tile_map = new_grid_tiles
	
	# initialize terrain data in tile_map
	var new_terrain_map = _init_terrain(self.terrain.tile_map)
	self.terrain.tile_map = new_terrain_map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# initialize terrain system
	_init_controller()

	# try to optimize terrain
	_optimize_terrain(self.terrain.tile_map)

	# if terrain optimized,
	if self.terrain_optimized:
		# update world data
		self.world.data.terrain = self.terrain
