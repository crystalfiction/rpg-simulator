class_name Biome extends RefCounted

# components
var Class: BiomeClass
enum BiomeClass {
	DESERT,
	SHRUBLAND,
	GRASSLAND,
	FOREST,
	TROPICAL,
	SWAMP,
}

var data = {
	"class": null,
	"class_v": "",
	"avg_texture": "",
	"avg_density": 0.0,
	"avg_rainfall": 0.0,
	"avg_drainage": 0.0,
	"ranges": {
		"rainfall_chance": 0.00,
		"density": [0.00, 0.00],
		"rainfall": [0.00, 0.00],
		"drainage": [0.00, 0.00]
	}
}


func get_biome_class() -> BiomeClass:
	var curr_biome = self.Class
	return curr_biome

func get_biome_class_string() -> String:
	var curr_biome = self.Class
	var key = BiomeClass.find_key(curr_biome)
	return key

func _calculate_biome_data() -> Dictionary:
	var density = [0.00, 0.00]
	var rainfall = [0.00, 0.00]
	var drainage = [0.00, 0.00]
	var rainfall_chance = 0.0
	match self.Class:
		BiomeClass.DESERT:
			rainfall_chance = 0.22
			density = [0.00, 1.00]
			rainfall = [0.00, 0.44]
			drainage = [0.44, 1.00]
		BiomeClass.SHRUBLAND:
			rainfall_chance = 0.44
			density = [0.33, 0.66]
			rainfall = [0.00, 0.44]
			drainage = [0.00, 1.00]
		BiomeClass.GRASSLAND:
			rainfall_chance = 0.66
			density = [0.33, 0.66]
			rainfall = [0.22, 0.66]
			drainage = [0.22, 0.88]
		BiomeClass.FOREST:
			rainfall_chance = 0.66
			density = [0.33, 0.88]
			rainfall = [0.44, 0.66]
			drainage = [0.44, 0.88]
		BiomeClass.TROPICAL:
			rainfall_chance = 0.88
			density = [0.33, 1.00]
			rainfall = [0.88, 1.00]
			drainage = [0.44, 1.00]
		BiomeClass.SWAMP:
			rainfall_chance = 0.88
			density = [0.33, 1.00]
			rainfall = [0.44, 1.00]
			drainage = [0.00, 0.44]

	var new_ranges = {
		"rainfall_chance": rainfall_chance,
		"density": density,
		"rainfall": rainfall,
		"drainage": drainage
	}
	return new_ranges

func _evaluate_biome_class(biome_data: Dictionary):
	if biome_data.avg_texture == "sand":
		# sand
		self.Class = BiomeClass.DESERT
	elif biome_data.avg_texture == "silt":
		# silt
		if biome_data.avg_rainfall >= 0 && biome_data.avg_rainfall < 0.22:
			# low rainfall
			self.Class = BiomeClass.SHRUBLAND
		elif biome_data.avg_rainfall >= 0.22 && biome_data.avg_rainfall < 0.44:
			# low-medium rainfall
			self.Class = BiomeClass.SHRUBLAND
		elif biome_data.avg_rainfall >= 0.44 && biome_data.avg_rainfall < 0.66:
			# medium rainfall
			if biome_data.avg_drainage >= 0 && biome_data.avg_drainage < 0.44:
				# low drainage
				self.Class = BiomeClass.GRASSLAND
			elif biome_data.avg_drainage >= 0.44 && biome_data.avg_drainage < 0.66:
				# low-medium drainage
				self.Class = BiomeClass.GRASSLAND
			elif biome_data.avg_drainage > 0.66 && biome_data.avg_drainage < 0.88:
				# medium drainage
				self.Class = BiomeClass.FOREST
			elif biome_data.avg_drainage > 0.88 && biome_data.avg_drainage <= 1:
				# high drainage
				self.Class = BiomeClass.GRASSLAND
		elif biome_data.avg_rainfall >= 0.66 && biome_data.avg_rainfall < 0.88:
			# medium-high rainfall
			if biome_data.avg_drainage >= 0 && biome_data.avg_drainage < 0.44:
				# low drainage
				self.Class = BiomeClass.SWAMP
			elif biome_data.avg_drainage >= 0.44 && biome_data.avg_drainage <= 1:
				# medium-high drainage
				self.Class = BiomeClass.FOREST
		elif biome_data.avg_rainfall >= 0.88 && biome_data.avg_rainfall <= 1:
			# high rainfall
			if biome_data.avg_drainage >= 0 && biome_data.avg_drainage < 0.66:
				# low-medium drainage
				self.Class = BiomeClass.SWAMP
			elif biome_data.avg_drainage >= 0.66 && biome_data.avg_drainage < 0.88:
				# medium-high drainage
				self.Class = BiomeClass.TROPICAL
			elif biome_data.avg_drainage >= 0.88 && biome_data.avg_drainage <= 1:
				# high drainage
				self.Class = BiomeClass.TROPICAL

func _init(biome_data: Dictionary) -> void:
	# initialize data
	for k in biome_data:
		self.data[k] = biome_data[k]
	
	# evaluate and update biome class data
	_evaluate_biome_class(biome_data)
	self.data.class = self.Class
	self.data.class_v = get_biome_class_string()
	# calculate biome terrain ranges
	self.data.ranges = _calculate_biome_data()