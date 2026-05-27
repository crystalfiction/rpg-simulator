extends Controller

# components
var resource_map: Array
var resource_iterations: int
var resources_optimized = null
# resources
var food_count = 0
var stone_count = 0
var food_factor = 0.11 # chance to generate resource on a given tile
var resources = []


# evaluates resource generation given a world's tile conditions
func _evaluate_resources(tile: Tile):
	# init resources as bool
	tile.data.resources = {"food": false}
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
				self.resources.append(tile)
				self.food_count += 1
	
	# return the tile with updated data
	return tile


## evaluates current terrain for resource conditions
func _evaluate_terrain(tile_map: Array):
	# loop through terrain
	var count = 0
	var avg_density = 0.0
	var avg_rainfall = 0.0
	var avg_water = 0.0
	var avg_drainage = 0.0
	var avg_erosion = 0.0
	for x in range(len(tile_map)):
		for y in range(len(tile_map[x])):
			var t = tile_map[x][y]
			# init resource data
			var new_tile = _evaluate_resources(t)
			t = new_tile
			# get metrics
			count += 1
			avg_density += t.data.terrain.density
			avg_rainfall += t.data.weather.rainfall
			avg_water += t.data.weather.water
			avg_drainage += t.data.weather.drainage
			avg_erosion += t.data.weather.erosion
	
	# update metrics
	avg_density /= count
	avg_rainfall /= count
	avg_water /= count
	avg_drainage /= count
	avg_erosion /= count
	
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
	if tile_map:
		return tile_map
	return ERR_INVALID_DATA


# initializes world resource system
func _init_controller(tile_map: Array):
	# evaluate the current terrain map and place resources
	var new_tile_map = _evaluate_terrain(tile_map)
	return new_tile_map


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# check if prior controllers have been properly initialized
	var world_controller = self.world.data.controller
	# initialize resource system
	if (world_controller.terrain_controller.terrain_optimized) && (
		world_controller.weather_controller.weather_optimized
	):
		var new_tile_map = _init_controller(self.world.data.terrain.tile_map)
		if new_tile_map:
			# update world refs
			self.world.data.terrain.tile_map = new_tile_map
			self.world.data.resources = self.resources
			## TODO: make this actually true
			self.resources_optimized = true
	
	print("Weather unable to initialize.")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
