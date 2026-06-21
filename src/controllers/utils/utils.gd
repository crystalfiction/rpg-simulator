## Main utils script entrypoint for entity.controller's
extends Node


# lambda functions returning grid offsets for cardinal positions
func _nw(idx: Vector2i) -> Vector2i: return idx + Vector2i(-1, -1)
func _n(idx: Vector2i) -> Vector2i: return idx + Vector2i(0, -1)
func _ne(idx: Vector2i) -> Vector2i: return idx + Vector2i(1, -1)
func _w(idx: Vector2i) -> Vector2i: return idx + Vector2i(-1, 0)
func _e(idx: Vector2i) -> Vector2i: return idx + Vector2i(1, 0)
func _sw(idx: Vector2i) -> Vector2i: return idx + Vector2i(-1, 1)
func _s(idx: Vector2i) -> Vector2i: return idx + Vector2i(0, 1)
func _se(idx: Vector2i) -> Vector2i: return idx + Vector2i(1, 1)

## gets and saves 8-D tile neighbors for a given entity,
## returns flattened neighbors array
func get_neighbors(entity: Entity, entities: Array) -> Array:
	# define neighbors array
	## populate with results of cardinal direction functions for 'entity'
	var directions = [
		_nw(entity.data.grid_idx), # value = result = grid_idx
		_n(entity.data.grid_idx),
		_ne(entity.data.grid_idx),
		_w(entity.data.grid_idx),
		_e(entity.data.grid_idx),
		_sw(entity.data.grid_idx),
		_s(entity.data.grid_idx),
		_se(entity.data.grid_idx)
	]
	
	# remove neighbors outside grid_bounds
	var n_constrained = []
	var grid_bounds = Vector2i(len(entities), len(entities[0]))
	# for each neighbor
	for idx in directions:
		# if within grid_bounds
		if (idx.x >= 0 && idx.x <= grid_bounds.x) && (
			idx.y >= 0 && idx.y <= grid_bounds.y):
			# append entity object to n_constrained
			var n_tile = get_object_by_grid(idx, entities)
			# if tile within grid bounds,
			if n_tile != null:
				# add to results
				n_constrained.append(n_tile)
	
	# return the constrained neighbors array
	return n_constrained

## gets and returns an entity object given the passed grid index and entities array
func get_object_by_grid(
	grid_idx: Vector2i,
	entities: Array,
):
	# loop through entities
	for x in range(len(entities)):
		for y in range(len(entities[x])):
			# if entity.data.grid_idx is a match, return
			if entities[x][y].data.grid_idx == grid_idx:
				return entities[x][y]

## converts grid_idx to world position and returns as Vector2i
func grid_to_world(grid_idx: Vector2i, grid_scale: Vector2i) -> Vector2i:
	return floor(grid_idx * grid_scale)

## converts world position to grid position and returns as Vector2i
func world_to_grid(world_pos: Vector2i, grid_scale: Vector2i) -> Vector2i:
	var world_pos_v = world_pos as Vector2
	var grid_scale_v = grid_scale as Vector2
	return (world_pos_v.floor() / grid_scale_v.floor()) as Vector2i

## gets the most prominent soil texture in a tile's given soil data
## according to total average soil density
## returns new texture as String
func get_soil_texture(entity: Entity) -> String:
	var keys = entity.data.keys()
	if "terrain" not in keys:
		return ""
	
	var soil_textures = ["sand", "silt", "clay"]
	var s_keys = entity.data.terrain.keys()
	var curr_texture = 0
	var new_texture = ""
	for t in soil_textures:
		if t in s_keys:
			var texture = entity.data.terrain[t]
			if texture >= curr_texture:
				curr_texture = texture
				new_texture = t
	
	return new_texture

## gets the most common string in an array and returns as String
func common_string(arr: Array) -> String:
	if arr.is_empty():
		return ""
	
	var counts = {}
	var most_common = ""
	var max_count = 0
	
	for item in arr:
		# Increment the count for each string
		counts[item] = counts.get(item, 0) + 1
		
		# Track the highest count seen so far
		if counts[item] > max_count:
			max_count = counts[item]
			most_common = item
			
	return most_common

## calculates the Z-score for a specific value based on an entire dataset
func z_score_normalize(value: float, neighbors: Array) -> float:
	if neighbors.size() == 0:
		return 0.0
	
	# calculate mean soil density in terrain
	var mean: float = 0.0
	var densities = []
	for n in neighbors:
		var d = n.data.terrain.density
		densities.append(d)
		mean += d
	mean /= densities.size()
	
	# calculate std of soil density in terrain
	var variance: float = 0.0
	for d in densities:
		variance += pow(d - mean, 2)
	variance /= densities.size()
	
	var std_dev: float = sqrt(variance)
	
	# calculate and return z_score
	if std_dev == 0:
		return 0.0 # Prevent division by zero if dataset has no variance
	
	return (value - mean) / std_dev

## accepts a terrain tile map
## returns an array of world resources
func get_resources(tile_map: Array) -> Array:
	var array = []
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			var t = tile_map[x][y]
			if t.data.resources.food:
				array.append(t)
	return array
