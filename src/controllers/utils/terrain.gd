# Terrain controller helper functions 
extends Node


# gets the most prominent soil texture in a tile given soil data
# returns new texture as String
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

## TODO: figure out if this is universal, return to utils if so
# gets the most common string in an array and returns
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
