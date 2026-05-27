extends Controller

# components
var weather_map: Array
var weather_optimized = null
var erosion_complete = null
var erosion_cycle = 0
var weather_iterations = 0
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
func _apply_erosion():
	var curr_map = weather_map
	var avg_erosion = 0.0
	var count = 0
	for x in range(curr_map.size()):
		for y in range(curr_map[x].size()):
			# tile
			var w = curr_map[x][y]
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
	return curr_map


# calculates erosion values per tile given water values
func _calculate_erosion():
	var avg_erosion = 0.0
	var avg_soil_density = 0.0
	var count = 0
	for x in range(weather_map.size()):
		for y in range(weather_map[x].size()):
			# tile
			var w = weather_map[x][y]
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
func _calculate_water():
	var avg_rainfall = 0.0
	var avg_drainage = 0.0
	var avg_water = 0.0
	var count = 0
	for x in range(weather_map.size()):
		for y in range(weather_map[x].size()):
			# tile
			var w = weather_map[x][y]
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
func _optimize_weather():
	print("Optimizing weather...")
	
	# calculate features
	var new_metrics: Dictionary
	var water_metrics = _calculate_water()
	new_metrics.merge(water_metrics)
	var erosion_metrics = _calculate_erosion()
	new_metrics.merge(erosion_metrics)
	
	## TODO: optimize features with metrics
	
	# run weather erosion cycle
	var complete = false
	while !complete:
		# apply erosion
		#var result = true
		var result = _apply_erosion()
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
			## TODO: loop optimization
			# terrain is optimized and valid
			complete = true
			erosion_complete = complete

	weather_iterations += 1
	weather_optimized = complete


# initializes the weather system controller
func _init_controller(terrain: Array):
	# init features
	rainfall = randf_range(rainfall_min, rainfall_max)
	
	## loop through tile entities and create init weather data
	var entities_array = []
	for x in range(len(terrain)):
		entities_array.append([])
		for y in range(len(terrain[x])):
			var e = terrain[x][y]
			# if tile
			if e is Tile:
				# initialize weather data
				var drainage = 1 - e.data.terrain.density # invert density
				drainage = clamp(drainage, drainage_min, drainage_max)
				e.data.weather = {
					"rainfall": rainfall,
					"drainage": drainage,
					"water": 0.0,
					"erosion": 0.0
				}
				# push to terrain entities array
				entities_array[x].append(e)
	
	# reset metrics
	weather_iterations = 0
	
	# validate the result
	var result = true
	if entities_array:
		# result valid, update terrain map/terrain state
		self.weather_map = entities_array
		result = self.weather_map
	else:
		# return error
		result = ERR_SCRIPT_FAILED
	return result


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get world controller
	var world_controller = self.world.data.controller
	# make sure terrain optimized
	if world_controller.terrain_controller.terrain_optimized:
		# initialize weather controller
		var result = _init_controller(self.world.data.tiles.objs)
		# validate initialization
		if result:
			# try to optimize weather
			result = _optimize_weather()
