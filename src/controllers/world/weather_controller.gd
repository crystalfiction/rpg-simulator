extends Controller

# refs

# components
var terrain: Terrain
var weather_optimized = null
var erosion_complete = null
var erosion_cycle = 0
var weather_iterations = 0

var rainfall: float
var rainfall_min = 0.22
var rainfall_max = 1.00
var drainage_min = 0.00
var drainage_max = 1.00

var erosion_factor = 0.01

var weather_metrics: Dictionary


# Weather Simulation

## applies erosion to the current weather_map given the paramaters
func _apply_erosion(curr_terrain: Array) -> Array:
	var avg_erosion = 0.0
	var count = 0
	var avg_density = 0.0
	for x in range(curr_terrain.size()):
		for y in range(curr_terrain[x].size()):
			# tile
			var w = curr_terrain[x][y]
			# apply erosion by sum
			w.data.weather.erosion += w.data.weather.erosion
			# reduce soil density by new erosion sum
			var new_soil_density = clamp(
				w.data.terrain.density - w.data.weather.erosion,
				self.parent.soil_density_min,
				self.parent.soil_density_max
			)
			w.data.terrain.density = new_soil_density
			# update texture string
			w.data.terrain.texture = self.Utils.get_soil_texture(w)
			# update metrics
			count += 1
			avg_density += w.data.terrain.density
			avg_erosion += w.data.weather.erosion
			
	# update metrics
	avg_erosion /= count
	avg_density /= count
	self.terrain.data.metrics.avg_density = snapped(avg_density, 0.001)
	var new_avg_texture = ""
	if avg_density >= 0 && avg_density < 0.33:
		new_avg_texture = "sand"
	elif avg_density >= 0.33 && avg_density < 0.66:
		new_avg_texture = "silt"
	elif avg_density >= 0.66 && avg_density <= 1:
		new_avg_texture = "clay"
	self.terrain.data.metrics.avg_texture = new_avg_texture

	# return new map
	return [curr_terrain, avg_erosion]

## calculates erosion values per tile given water values
func _calculate_erosion(curr_terrain: Array) -> Dictionary:
	var avg_erosion = 0.0
	var count = 0
	for x in range(curr_terrain.size()):
		for y in range(curr_terrain[x].size()):
			# tile
			var w = curr_terrain[x][y]
			var erosion = (
				((w.data.weather.water) *
				(1 + w.data.weather.rainfall) *
				(1 - w.data.weather.drainage) *
				(1 - w.data.terrain.density)) * erosion_factor
			)
			w.data.weather.erosion = erosion
			# update metrics
			avg_erosion += w.data.weather.erosion
			count += 1
			
	# update metrics
	avg_erosion /= count
	var metrics = {
		"avg_erosion": avg_erosion
	}
	
	# return metrics
	return metrics

## calculates water values per tile given rainfall, drainage
func _calculate_water(curr_terrain: Array) -> Dictionary:
	var avg_rainfall = 0.0
	var avg_drainage = 0.0
	var avg_water = 0.0
	var count = 0
	for x in range(curr_terrain.size()):
		for y in range(curr_terrain[x].size()):
			# tile
			var w = curr_terrain[x][y]
			# calculate water value
			var water = clamp(
				(w.data.weather.rainfall) *
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
func _optimize_weather(curr_terrain: Terrain) -> Terrain:
	FileLogger.log_message(self , "Optimizing weather...")
	
	# calculate features
	var tile_map = curr_terrain.data.tile_map
	var new_metrics: Dictionary
	var water_metrics = _calculate_water(tile_map)
	new_metrics.merge(water_metrics)
	var erosion_metrics = _calculate_erosion(tile_map)
	new_metrics.merge(erosion_metrics)
	
	#get metrics
	for m in new_metrics:
		new_metrics[m] = snapped(new_metrics[m], 0.001)
	self.weather_metrics = new_metrics
	
	# run weather erosion cycle
	var n_cycles = 2
	var total_erosion = 0
	var final: Array = curr_terrain.data.tile_map
	for i in range(n_cycles):
		# apply erosion
		self.erosion_cycle += 1
		var results = _apply_erosion(final)
		final = results[0]
		total_erosion += results[1]
	
	
	# curr_terrain is optimized and valid
	self.erosion_complete = true
	total_erosion /= n_cycles
	new_metrics.avg_erosion = snapped(total_erosion, 0.0001)
	
	self.weather_iterations += 1
	self.weather_optimized = true

	# log metrics if complete
	var msg = (
		"avg_rainfall: " + str(snapped(new_metrics.avg_rainfall, 0.001)) + " | " +
		"avg_drainage: " + str(snapped(new_metrics.avg_drainage, 0.001)) + " | " +
		"avg_water: " + str(snapped(new_metrics.avg_water, 0.001)) + " | " +
		"avg_erosion: " + str(snapped(new_metrics.avg_erosion, 0.0001)) + " | " +
		"erosion_cycles: " + str(snapped(self.erosion_cycle, 0.001))
	)
	FileLogger.log_message(self , msg)

	tile_map = final
	curr_terrain.data.tile_map = tile_map
	return curr_terrain

func _calculate_rainfall(curr_terrain: Terrain) -> void:
	# check if biome exists
	var biome = curr_terrain.data.biome
	if biome == null:
		self.rainfall = randf_range(
			rainfall_min,
			rainfall_max)
	else:
		self.rainfall = randf_range(
			biome.data.ranges.rainfall[0],
			biome.data.ranges.rainfall[1])


# Weather Initialization

## initializes the weather system controller
func init_controller() -> void:
	# check biome
	var biome = self.terrain.data.biome if self.terrain.data.biome != null else null
	# calculate rain
	_calculate_rainfall(self.terrain)
	
	# init features
	var tile_map = self.terrain.data.tile_map
	## loop through tile entities and create init weather data
	for x in range(len(tile_map)):
		for y in range(len(tile_map[x])):
			var t = tile_map[x][y]
			# initialize weather data
			if biome == null:
				var rand_r = randf_range(drainage_min, drainage_max)
				var drainage = rand_r
				# drainage = clamp(drainage, drainage_min, drainage_max)
				t.data.weather = {
					"rainfall": self.rainfall,
					"drainage": drainage,
					"water": 0.0,
					"erosion": 0.0
				}
			# if biome passed,
			else:
				var drainage = 1 - t.data.terrain.density # invert density
				drainage = clamp(
					drainage,
					biome.data.ranges.drainage[0],
					biome.data.ranges.drainage[1]
				)
				t.data.weather = {
					"rainfall": self.rainfall,
					"drainage": drainage,
					"water": t.data.weather.water,
					"erosion": t.data.weather.erosion
				}
	
	# optimize weather
	self.terrain = _optimize_weather(self.terrain)

	# reset metrics
	self.weather_iterations = 0

	# update terrain
	self.terrain.data.weather = self.weather_metrics
	self.terrain.data.tile_map = tile_map
	self.terrain.data.on_change.call()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# initialize controller with terrain given on initialization
	init_controller()


# Weather Processing

## processes weather-level terrain data
func _process_weather():
	var time_controller = self.parent.parent.time_controller
	if time_controller:
		var weather_interval = 7
		if time_controller.cycling && (
			int(time_controller.cycles) % weather_interval == 0
		):
			# # calculate weather cycle
			# _calculate_rainfall(self.terrain)
			# # update terrain
			# self.terrain.data.weather = self.weather_metrics
			# self.terrain.data.on_change.call()
			pass

# Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_process_weather()
