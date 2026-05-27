extends Node


# lambda functions returning grid offsets for cardinal positions
func nw(idx: Vector2i): return idx + Vector2i(-1, -1)
func n(idx: Vector2i): return idx + Vector2i(0, -1)
func ne(idx: Vector2i): return idx + Vector2i(1, -1)
func w(idx: Vector2i): return idx + Vector2i(-1, 0)
func e(idx: Vector2i): return idx + Vector2i(1, 0)
func sw(idx: Vector2i): return idx + Vector2i(-1, 1)
func s(idx: Vector2i): return idx + Vector2i(0, 1)
func se(idx: Vector2i): return idx + Vector2i(1, 1)


# gets and saves 8-D neighbors for a given entity
func get_neighbors(entity: Entity, entities: Array):
	# define neighbors array
	## populate with results of cardinal direction functions for 'entity'
	var neighbors = [
		nw(entity.data.grid_idx),
		n(entity.data.grid_idx),
		ne(entity.data.grid_idx),
		w(entity.data.grid_idx),
		e(entity.data.grid_idx),
		sw(entity.data.grid_idx),
		s(entity.data.grid_idx),
		se(entity.data.grid_idx)
	]
	
	# remove neighbors outside grid_bounds
	var n_constrained = []
	var grid_bounds = Vector2i(len(entities), len(entities[0]))
	# for each neighbor
	for idx in neighbors:
		# if within grid_bounds
		if (idx.x >= 0 && idx.x <= grid_bounds.x) && (
			idx.y >= 0 && idx.y <= grid_bounds.y):
			# append entity object to n_constrained
			var obj = get_object_by_grid(idx, entities)
			if !obj == null:
				n_constrained.append(obj)
	
	# return the constrained neighbors array
	return n_constrained


# gets an entity object given the passed grid index and entities array
func get_object_by_grid(grid_idx: Vector2i, entities: Array):
	# loop through entities
	for x in range(len(entities)):
		for y in range(len(entities[x])):
			# if entity.data.grid_idx is a match, return
			if entities[x][y].data.grid_idx == grid_idx:
				return entities[x][y]


# gets an entity object given the passed grid index and entities array
func get_objects_by_grid(grid_idx: Vector2i, entities: Array):
	# loop through entities
	var objects = []
	for x in range(len(entities)):
		for y in range(len(entities[x])):
			# if entity.data.grid_idx is a match, return
			if entities[x][y].data.grid_idx == grid_idx:
				objects.append(entities[x][y])
	return objects


# helper function converting grid position to world position
func grid_to_world(grid_idx: Vector2i, grid_scale: Vector2i) -> Vector2:
	return floor(grid_idx * grid_scale)


# helper function converting world position to grid position
func world_to_grid(world_pos: Vector2i, grid_scale: Vector2i) -> Vector2i:
	return floor(world_pos / grid_scale)


# gets the most common string in an array
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


# Calculates the Z-score for a specific value based on an entire dataset
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


# gets the most prominent soil texture given soil data
func get_soil_texture(entity: Entity):
	var keys = entity.data.keys()
	if "terrain" not in keys:
		return
	
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
