extends Controller

# components
var resource_map: Array
var resource_iterations: int
var resources_optimized = null
# resources
var food_count = 0
var stone_count = 0
var food_factor = 0.11 # chance to generate resources on a given tile
#var stone_factor = 0.22
var resource_tiles = []
var resources_left = 0


# evaluates resource generation given a world's tile conditions
func _evaluate_resources(tile: Tile):
	# init resources as bool
	var resources = {
		"food": false,
	}
	tile.data.resources = resources
	for k in tile.data.resources.keys():
		# test conditions depending on resource type
		var rand_f = randf_range(0, 1)
		if k == "food":
			var food_conditions = true if (
				(tile.data.terrain.density >= 0.44 && tile.data.terrain.density <= 0.66)
				&& (tile.data.weather.rainfall >= 0.22 && tile.data.weather.rainfall <= 1)
				&& (tile.data.weather.drainage >= 0.22 && tile.data.weather.drainage <= 0.88)
				&& (rand_f <= food_factor)
			) else false
			if food_conditions:
				tile.data.resources.food = true
				self.resource_tiles.append(tile)
				self.food_count += 1
	
	# return the tile with update data
	return tile


## evaluates current terrain for resource conditions
func _evaluate_terrain(terrain: Array):
	# return if invalid
	if !terrain:
		return false
	
	# loop through terrain
	var count = 0
	var avg_density = 0.0
	var avg_rainfall = 0.0
	var avg_water = 0.0
	var avg_drainage = 0.0
	var avg_erosion = 0.0
	for x in range(len(terrain)):
		for y in range(len(terrain[x])):
			var e = terrain[x][y]
			# if tile
			if e is Tile:
				# init resource data
				var new_tile = _evaluate_resources(e)
				e = new_tile
				# get metrics
				count += 1
				avg_density += e.data.terrain.density
				avg_rainfall += e.data.weather.rainfall
				avg_water += e.data.weather.water
				avg_drainage += e.data.weather.drainage
				avg_erosion += e.data.weather.erosion
	
	# update metrics
	avg_density /= count
	avg_rainfall /= count
	avg_water /= count
	avg_drainage /= count
	avg_erosion /= count
	self.resources_left = (self.food_count + self.stone_count)
	
	# print verbose metrics
	var metrics = {
		"avg_density": avg_density,
		"avg_rainfall": avg_rainfall,
		"avg_drainage": avg_drainage,
		"avg_water": avg_water,
		"avg_erosion": avg_erosion,
	}
	var keys = metrics.keys()
	var metrics_v = ""
	for m in range(keys.size()):
		metrics_v += keys[m] + ": " + str(snapped(metrics[keys[m]], 0.001))
		if m < keys.size() - 1:
			metrics_v += " | "
	print(metrics_v)
	print(
		"resources_generated: " + str(food_count) + " food"
	)
	
	# return metrics if valid
	if metrics:
		return [terrain, metrics]
	else:
		return ERR_INVALID_DATA


# initializes world resource system
func _init_controller(terrain: Array):
	# evaluate the current terrain map and get metrics
	var result = _evaluate_terrain(terrain)
	var curr_terrain = result[0]
	var metrics = result[1]
	
	# calculate resources for the current terrain map
	#result = _calculate_resources(curr_terrain, metrics)
	## TODO: update tile data with results
	
	# update world refs
	self.world.data.tiles.data.resources = resource_tiles
	
	# validate the result
	if !result:
		result = "Invalid resource map."
	else:
		# result valid, update terrain map/terrain state
		self.resource_map = terrain
		result = self.resource_map
	
	# return result
	return result


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# check if prior controllers have been properly initialized
	var world_controller = self.world.data.controller
	# initialize resource system
	if (world_controller.terrain_controller.terrain_optimized) && (
		world_controller.weather_controller.weather_optimized
	):
		var result = _init_controller(self.world.data.tiles.objs)
		if !result:
			# result invalid
			# print error
			print(result)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
