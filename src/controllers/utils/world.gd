# World controller helper functions 
extends Node


# lambda functions returning grid offsets for cardinal positions
# used in get_neighbors
func _nw(idx: Vector2i): return idx + Vector2i(-1, -1)
func _n(idx: Vector2i): return idx + Vector2i(0, -1)
func _ne(idx: Vector2i): return idx + Vector2i(1, -1)
func _w(idx: Vector2i): return idx + Vector2i(-1, 0)
func _e(idx: Vector2i): return idx + Vector2i(1, 0)
func _sw(idx: Vector2i): return idx + Vector2i(-1, 1)
func _s(idx: Vector2i): return idx + Vector2i(0, 1)
func _se(idx: Vector2i): return idx + Vector2i(1, 1)

# gets and saves 8-D tile neighbors for a given entity
func get_neighbors(entity: Entity, entities: Array):
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

# gets an entity object given the passed grid index and entities array
func get_object_by_grid(grid_idx: Vector2i, entities: Array):
	# loop through entities
	for x in range(len(entities)):
		for y in range(len(entities[x])):
			# if entity.data.grid_idx is a match, return
			if entities[x][y].data.grid_idx == grid_idx:
				return entities[x][y]

# converts grid_idx to world position and returns as Vector2i
func grid_to_world(grid_idx: Vector2i, grid_scale: Vector2i) -> Vector2i:
	return floor(grid_idx * grid_scale)

# converts world position to grid position and returns as Vector2i
func world_to_grid(world_pos: Vector2i, grid_scale: Vector2i) -> Vector2i:
	return floor(world_pos / grid_scale)
