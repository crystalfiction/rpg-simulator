extends Controller

# components
var weather_optimized = null
var erosion_complete = null
var erosion_cycle = 0
var weather_iterations = 0
var weather = {
	"tile_map": []
}
# water
var rainfall_min = 0.22
var rainfall_max = 1.00
var drainage_min = 0.00
var drainage_max = 1.00
var rainfall: float
var soil_density_factor = 0.66
# erosion
var erosion_factor = 0.11


# applies erosion to the current weather_map given the paramaters
func _apply_erosion(tile_map: Array):
	var avg_erosion = 0.0
	var count = 0
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# tile
			var w = tile_map[x][y]
			# apply erosion
			w.data.weather.erosion += w.data.weather.erosion
			# reduce soil density by erosion value
			var new_soil_density = clamp(
				w.data.terrain.density - w.data.weather.erosion,
				world.data.controller.terrain_controller.soil_density_min,
				world.data.controller.terrain_controller.soil_density_max
			)
			w.data.terrain.density = new_soil_density
			# update metrics
			count += 1
			avg_erosion += w.data.weather.erosion
			
	# update metrics
	avg_erosion /= count
	
	# return new map
	return tile_map


# calculates erosion values per tile given water values
func _calculate_erosion(tile_map: Array):
	var avg_erosion = 0.0
	var avg_soil_density = 0.0
	var count = 0
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# tile
			var w = tile_map[x][y]
			var erosion = (
				((w.data.weather.water) *
				(w.data.weather.drainage) *
				(1 - w.data.terrain.density)) * erosion_factor
			)
			w.data.weather.erosion = erosion
			# update metrics
			avg_erosion += w.data.weather.erosion
			avg_soil_density += w.data.terrain.density
			count += 1
			
	# update metrics
	avg_erosion /= count
	avg_soil_density /= count
	var metrics = {
		"avg_erosion": avg_erosion
	}
	
	# return metrics
	return metrics


# calculates water values per tile given rainfall, drainage
func _calculate_water(tile_map: Array):
	var avg_rainfall = 0.0
	var avg_drainage = 0.0
	var avg_water = 0.0
	var count = 0
	for x in range(tile_map.size()):
		for y in range(tile_map[x].size()):
			# tile
			var w = tile_map[x][y]
			# calculate water value
			var water = clamp(
				(w.data.weather.rainfall ** 2) *
				(1 - w.data.weather.drainage) *
				(1 + w.data.terrain.density),
				0, 1
			)
			w.data.weather.water = water
			# update metrics
			avg_rainfall += w.data.weather.rainfall
			avg_drainage += w.data.weather.drainage
			avg_water += w.data.weather.water
			count += 1
			
	# update metrics
	avg_rainfall /= count
	avg_drainage /= count
	avg_water /= count
	var metrics = {
		"avg_rainfall": avg_rainfall,
		"avg_drainage": avg_drainage,
		"avg_water": avg_water
	}
	
	# return metrics
	return metrics


# processes weather for the current weather_map
func _optimize_weather(tile_map: Array):
	print("Optimizing weather...")
	
	# calculate features
	var new_metrics: Dictionary
	var water_metrics = _calculate_water(tile_map)
	new_metrics.merge(water_metrics)
	var erosion_metrics = _calculate_erosion(tile_map)
	new_metrics.merge(erosion_metrics)
	
	## TODO: optimize features with metrics
	
	# run weather erosion cycle
	var complete = false
	var final: Array
	while !complete:
		# apply erosion
		#var result = true
		var result = _apply_erosion(tile_map)
		erosion_cycle += 1
		# log metrics if complete
		print(
			"avg_rainfall: " + str(snapped(new_metrics.avg_rainfall, 0.001)) + " | ",
			"avg_drainage: " + str(snapped(new_metrics.avg_drainage, 0.001)) + " | ",
			"avg_water: " + str(snapped(new_metrics.avg_water, 0.001)) + " | ",
			"avg_erosion: " + str(snapped(new_metrics.avg_erosion * erosion_cycle, 0.001)) + " | ",
			"erosion_cycles: " + str(snapped(erosion_cycle, 0.001)),
		)
		# test result
		if result:
			## TODO: elaborate on optimization
			# terrain is optimized and valid
			complete = true
			erosion_complete = complete
			final = result

	weather_iterations += 1
	weather_optimized = complete

	return final


# initializes the weather system controller
func _init_controller(terrain: Array):
	# init features
	rainfall = randf_range(rainfall_min, rainfall_max)
	
	## loop through tile entities and create init weather data
	for x in range(len(terrain)):
		for y in range(len(terrain[x])):
			var e = terrain[x][y]
			# initialize weather data
			var drainage = 1 - e.data.terrain.density # invert density
			drainage = clamp(drainage, drainage_min, drainage_max)
			e.data.weather = {
				"rainfall": rainfall,
				"drainage": drainage,
				"water": 0.0,
				"erosion": 0.0
			}
	
	# reset metrics
	weather_iterations = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get world controller
	var world_controller = self.world.data.controller
	# make sure terrain optimized
	if world_controller.terrain_controller.terrain_optimized:
		# initialize weather controller
		_init_controller(self.world.data.terrain.tile_map)
		# optimize weather
		var new_tile_map = _optimize_weather(self.world.data.terrain.tile_map)
		if weather_optimized:
			self.world.data.terrain.tile_map = new_tile_map