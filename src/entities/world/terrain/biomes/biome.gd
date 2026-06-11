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
	"avg_density": 0.0,
	"avg_texture": "",
	"avg_rainfall": 0.0,
	"avg_drainage": 0.0,
	"avg_water": 0.0,
}


func get_biome_class_string() -> String:
	var curr_biome = self.Class
	var key = BiomeClass.find_key(curr_biome)
	return key

func evaluate_biome_class(biome_data: Dictionary):
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
			self.Class = BiomeClass.GRASSLAND
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
				self.Class = BiomeClass.SHRUBLAND
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
				self.Class = BiomeClass.FOREST

func _init(biome_data: Dictionary) -> void:
	# initialize data
	for k in biome_data:
		self.data[k] = biome_data[k]
	
	# evaluate and update biome class data
	evaluate_biome_class(biome_data)
	self.data.class = self.Class
	self.data.class_v = get_biome_class_string()