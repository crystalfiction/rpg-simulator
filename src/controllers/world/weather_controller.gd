extends Controller

# refs
var FileLogger

# components
var tile_map: Array
var weather_optimized = null
var erosion_complete = null
var erosion_cycle = 0
var weather_iterations = 0

var rainfall: float
var rainfall_min = 0.22
var rainfall_max = 1.00
var drainage_min = 0.00
var drainage_max = 1.00

var erosion_factor = 0.11

var weather_metrics: Dictionary

# Weather Simulation

## applies erosion to the current weather_map given the paramaters
func _apply_erosion(terrain: Array) -> Array:
	var utils = self.world.data.controller.utils
	var avg_erosion = 0.0
	var count = 0
	var avg_density = 0.0
	for x in range(terrain.size()):
		for y in range(terrain[x].size()):
			# tile
			var w = terrain[x][y]
			# apply erosion by sum
			w.data.weather.erosion += w.data.weather.erosion
			# reduce soil density by new erosion sum
			var new_soil_density = clamp(
				w.data.terrain.density - w.data.weather.erosion,
				world.data.controller.terrain_controller.soil_density_min,
				world.data.controller.terrain_controller.soil_density_max
			)
			w.data.terrain.density = new_soil_density
			# update texture string
			w.data.terrain.texture = utils.get_soil_texture(w)
			# update metrics
			count += 1
			avg_density += w.data.terrain.density
			avg_erosion += w.data.weather.erosion
			
	# update metrics
	avg_erosion /= count
	avg_density /= count
	self.world.data.terrain.data.metrics.avg_density = snapped(avg_density, 0.001)
	
	var new_avg_texture = ""
	if avg_density >= 0 && avg_density < 0.33:
		new_avg_texture = "sand"
	elif avg_density >= 0.33 && avg_density < 0.66:
		new_avg_texture = "silt"
	elif avg_density >= 0.66 && avg_density <= 1:
		new_avg_texture = "clay"
	
	self.world.data.terrain.data.metrics.avg_texture = new_avg_texture

	# return new map
	return terrain

## calculates erosion values per tile given water values
func _calculate_erosion(terrain: Array) -> Dictionary:
	var avg_erosion = 0.0
	var avg_soil_density = 0.0
	var count = 0
	for x in range(terrain.size()):
		for y in range(terrain[x].size()):
			# tile
			var w = terrain[x][y]
			var erosion = (
				((w.data.weather.water) *
				(1 - w.data.weather.drainage) *
				(1 - w.data.terrain.density ** 2)) * erosion_factor
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

## calculates water values per tile given rainfall, drainage
func _calculate_water(terrain: Array) -> Dictionary:
	var avg_rainfall = 0.0
	var avg_drainage = 0.0
	var avg_water = 0.0
	var count = 0
	for x in range(terrain.size()):
		for y in range(terrain[x].size()):
			# tile
			var w = terrain[x][y]
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

## processes weather for the current weather_map
func _optimize_weather(terrain: Array) -> Array:
	FileLogger.log_message(self , "Optimizing weather...")
	
	# calculate features
	var new_metrics: Dictionary
	var water_metrics = _calculate_water(terrain)
	new_metrics.merge(water_metrics)
	var erosion_metrics = _calculate_erosion(terrain)
	new_metrics.merge(erosion_metrics)
	
	## TODO: optimize features with metrics
	for m in new_metrics:
		new_metrics[m] = snapped(new_metrics[m], 0.001)
	self.weather_metrics = new_metrics
	
	# run weather erosion cycle
	var n_cycles = 1
	var final: Array = terrain
	for i in range(n_cycles):
		# apply erosion
		final = _apply_erosion(final)
		self.erosion_cycle += 1
		# log metrics if complete
		var msg = (
			"avg_rainfall: " + str(snapped(new_metrics.avg_rainfall, 0.001)) + " | " +
			"avg_drainage: " + str(snapped(new_metrics.avg_drainage, 0.001)) + " | " +
			"avg_water: " + str(snapped(new_metrics.avg_water, 0.001)) + " | " +
			"avg_erosion: " + str(snapped(new_metrics.avg_erosion * erosion_cycle, 0.001)) + " | " +
			"erosion_cycles: " + str(snapped(self.erosion_cycle, 0.001))
		)
		FileLogger.log_message(self , msg)
	
	# terrain is optimized and valid
	erosion_complete = true
	
	weather_iterations += 1
	weather_optimized = true

	return final

# Weather Initialization

## initializes the weather system controller
func init_controller(terrain: Array) -> void:
	# init features
	rainfall = randf_range(rainfall_min, rainfall_max)
	
	## loop through tile entities and create init weather data
	for x in range(len(terrain)):
		for y in range(len(terrain[x])):
			var t = terrain[x][y]
			# initialize weather data
			var drainage = 1 - t.data.terrain.density # invert density
			drainage = clamp(drainage, drainage_min, drainage_max)
			t.data.weather = {
				"rainfall": rainfall,
				"drainage": drainage,
				"water": 0.0,
				"erosion": 0.0
			}
	
	# reset metrics
	weather_iterations = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get FileLogger
	self.FileLogger = $"/root/FileLogger"

	# initialize controller with terrain given on initialization
	init_controller(self.tile_map)
	# optimize weather
	var new_tile_map = _optimize_weather(self.tile_map)
	# if weather optimized
	if weather_optimized:
		# update terrain.weather with new weather data
		var terrain = self.world.data.terrain
		terrain.data.weather = self.weather_metrics
		terrain.data.tile_map = new_tile_map

# Weather Processing

## processes weather-level terrain data
func _process_weather():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
