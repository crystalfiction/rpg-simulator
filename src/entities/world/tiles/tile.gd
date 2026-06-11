class_name Tile extends Entity

# refs
var soil_10yr = preload("res://src/assets/world/tile/soil_10YR.tres")
var soil_5yr = preload("res://src/assets/world/tile/soil_5YR.tres")
var soil_10r = preload("res://src/assets/world/tile/soil_10R.tres")

# components
@export var label_density: Label
@export var label_water: Label
@export var label_erosion: Label
@export var label_resources: Label
@export var label_grid_x: Label
@export var label_grid_y: Label

@export var tile_terrain: ColorRect
@export var tile_weather: ColorRect

var init_tile: Resource = preload("res://src/entities/world/tiles/tile.tscn")
var init_data: Dictionary = {
	"world": "",
	"grid_idx": Vector2i(0, 0),
	"terrain": {},
	"weather": {},
	"resources": {
		"food": false,
	},
	"encounters": {},
}

# Tile Initialization

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# init color
	_update_color(self.data)
	# init label text
	_update_label_text(self.data)

## initializes the entity scene
func init_scene() -> Sprite2D:
	var new_scene = self.init_tile.instantiate()
	return new_scene

## initializes the entity
func _init() -> void:
	self.Type = EntityType.TILE
	for k in self.init_data:
		self.data[k] = init_data[k]

# Tile Processing

# determines which color to render depending on tile data
func _update_color(tile_data: Dictionary):
	var keys = tile_data.keys()
	var gradients = [soil_10r, soil_5yr, soil_10yr]
	var new_color = Color()
	if "terrain" in keys:
		if "weather" in tile_data && "water" in tile_data.weather:
			# define water gradient
			var water = tile_data.weather.water
			
			# define soil gradient
			var new_gradient
			if water >= 0 && water < 0.33:
				new_gradient = gradients[0]
			elif water >= 0.33 && water < 0.66:
				new_gradient = gradients[1]
			elif water >= 0.66 && water <= 1:
				new_gradient = gradients[2]
			# apply gradient based on water content
			self.texture.gradient = new_gradient
				
		if "density" in tile_data.terrain:
			# sample gradient
			new_color = self.texture.gradient.sample(tile_data.terrain.density)
	
	# update color
	self.tile_terrain.color = new_color

# determines which label text to render given tile data
func _update_label_text(tile_data: Dictionary):
	# check for tile data to label in order of importance
	var keys = tile_data.keys()
	var labels = [
		self.label_density,
		self.label_water,
		self.label_erosion,
		self.label_resources,
		self.label_grid_x,
		self.label_grid_y
	]
	for l in labels:
		# update resource labels
		if "resources" in keys:
			if l == self.label_resources:
				var new_text = ""
				if tile_data.resources.food:
					new_text = "+"
				l.text = new_text

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# update label text/color if data changes
	_update_color(self.data)
	_update_label_text(self.data)
