extends Controller

# refs

# components
var terrain: Terrain
var resource_iterations: int
var resources_optimized = null
var resource_count = 0

var food_factor = 0.22 # chance to generate food on a given tile


# Resource Generation

## evaluates resource generation given a world's tile conditions
## returns the tile with resource flag
func _evaluate_resources(tile: Tile) -> Tile:
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
				self.resource_count += 1
	
	# return the tile with updated data
	return tile

## evaluates current terrain for resource conditions
## returns update tile_map
func _evaluate_terrain(tile_map: Array) -> Array:
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
		"avg_rainfall": avg_rainfall,
		"avg_drainage": avg_drainage,
		"avg_water": avg_water,
		"avg_erosion": avg_erosion,
		"avg_density": avg_density,
	}
	var keys = metrics.keys()
	var metrics_v = ""
	for m in range(keys.size()):
		metrics_v += keys[m] + ": " + str(snapped(metrics[keys[m]], 0.0001))
		if m < keys.size() - 1:
			metrics_v += " | "
	FileLogger.log_message(self , metrics_v)
	FileLogger.log_message(self ,
		"resources_generated: " + str(self.resource_count)
	)
	
	return tile_map

# Resource Initialization

## initializes world resource system
func init_controller() -> void:
	# evaluate the current terrain map and place resources
	var tile_map = _evaluate_terrain(self.terrain.data.tile_map)
	# update world resource count if valid
	self.terrain.data.resources.count = self.resource_count
	self.resource_count = 0
	self.terrain.data.tile_map = tile_map
	self.terrain.data.on_change.call()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# initialize resource system
	init_controller()

# Resource Processing

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
