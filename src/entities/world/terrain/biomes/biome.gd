class_name Biome extends RefCounted

# components
var Class: BiomeClass
enum BiomeClass {
	DESERT,
	GRASSLAND,
	FOREST,
	WETLANDS,
}

var data = {
	"class": self.Class,
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

static func get_random_biome() -> BiomeClass:
	var biomes = Biome.BiomeClass
	var r_biome = biomes.values().pick_random()
	return r_biome

func _calculate_biome_data() -> Dictionary:
	var density = [0.00, 0.00]
	var rainfall = [0.00, 0.00]
	var drainage = [0.00, 0.00]
	match self.Class:
		BiomeClass.DESERT:
			density = [0.00, 0.88]
			rainfall = [0.33, 0.66]
			drainage = [0.44, 1.00]
		BiomeClass.GRASSLAND:
			density = [0.22, 0.88]
			rainfall = [0.22, 0.66]
			drainage = [0.22, 0.66]
		BiomeClass.FOREST:
			density = [0.33, 1.00]
			rainfall = [0.44, 1.00]
			drainage = [0.44, 0.88]
		BiomeClass.WETLANDS:
			density = [0.33, 1.00]
			rainfall = [0.44, 1.00]
			drainage = [0.00, 0.44]

	var new_ranges = {
		"density": density,
		"rainfall": rainfall,
		"drainage": drainage
	}
	return new_ranges

func _init(biome_class: BiomeClass) -> void:
	# initialize data
	self.Class = biome_class
	self.data.class_v = get_biome_class_string()
	# calculate biome terrain ranges
	self.data.ranges = _calculate_biome_data()