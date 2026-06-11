class_name Terrain extends Entity

# components
var init_terrain = {
	"grid": [],
	"tile_map": [],
	"map_complete": false,
	"map_count": 0,
	"metrics": {},
	"biome": null,
	"weather": {},
	"resources": {},
	"encounters": {}
}


func get_terrain_biome() -> Biome:
	var biome_data = {
		"avg_density": self.data.metrics.avg_density,
		"avg_texture": self.data.metrics.avg_texture,
		"avg_rainfall": self.data.weather.avg_rainfall,
		"avg_drainage": self.data.weather.avg_drainage,
		"avg_water": self.data.weather.avg_water
	}
	var new_biome = Biome.new(biome_data)
	self.data.biome = new_biome
	return self.data.biome


## initializes the entity
func _init() -> void:
	self.Type = EntityType.TERRAIN
	for k in self.init_terrain:
		self.data[k] = init_terrain[k]