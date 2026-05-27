class_name Tile extends Entity

# references
var soil_10yr = preload("res://src/assets/world/tile/soil_10YR.tres")
var soil_5yr = preload("res://src/assets/world/tile/soil_5YR.tres")
var soil_10r = preload("res://src/assets/world/tile/soil_10R.tres")

var world: World

# ui components
@export var label_density: Label
@export var label_water: Label
@export var label_erosion: Label
@export var label_resources: Label
@export var label_encounters: Label
@export var label_grid_x: Label
@export var label_grid_y: Label

@export var tile_color: ColorRect

var data = {
	"uid": 0,
	"grid_idx": Vector2i(0, 0),
	# contains world system data at runtime
}


# determines which color to render depending on tile data
func _update_color(tile_data: Dictionary):
	var keys = tile_data.keys()
	var gradients = [soil_10r, soil_5yr, soil_10yr]
	var new_color = Color()
	if "terrain" in keys:
		if "weather" in keys && "water" in tile_data.weather:
			# define water gradient
			var water = tile_data.weather.water
			#self.weather.color = water_gradient.sample(water)
			
			# define soil gradient
			var new_gradient
			if water >= 0 && water < 0.33:
				new_gradient = gradients[0]
			elif water >= 0.33 && water < 0.66:
				new_gradient = gradients[1]
			elif water >= 0.66 && water <= 1:
				new_gradient = gradients[2]
			# apply gradient
			self.texture.gradient = new_gradient
				
		if "density" in tile_data.terrain:
			# sample gradient
			new_color = self.texture.gradient.sample(tile_data.terrain.density)
			
	
	# update color
	self.tile_color.color = new_color


# determines which label text to render given tile data
func _update_label_text(tile_data: Dictionary):
	# check for tile data to label in order of importance
	var keys = tile_data.keys()
	var labels = [
		self.label_density,
		self.label_water,
		self.label_erosion,
		self.label_resources,
		self.label_encounters,
		self.label_grid_x,
		self.label_grid_y
	]
	for l in labels:
		# update terrain labels
		if "grid_idx" in keys:
			if l == self.label_grid_x:
				l.text = str(self.data.grid_idx.x) + ","
			if l == self.label_grid_y:
				l.text = str(self.data.grid_idx.y)
		if "terrain" in keys:
			if l == self.label_density:
				# soil density label
				l.text = str(snapped(tile_data.terrain.density, 0.01))
				# map label alpha to value density
				l.add_theme_color_override("font_color", Color(1, 1, 1, tile_data.terrain.density + 0.22))
		# update weather labels
		if "weather" in keys:
			if l == self.label_water:
				# water label
				l.text = str(snapped(tile_data.weather.water, 0.01))
				# map label alpha to value density
				l.add_theme_color_override("font_color", Color(1, 1, 1, tile_data.weather.water + 0.44))
			if l == self.label_erosion:
				# erosion label
				l.text = str(snapped(tile_data.weather.erosion, 0.01))
				# map label alpha to value density
				l.add_theme_color_override("font_color", Color(1, 1, 1, tile_data.weather.erosion + 0.66))
		# update resource labels
		if "resources" in keys:
			if l == self.label_resources:
				var new_text = ""
				if tile_data.resources.food:
					new_text = "+"
				l.text = new_text
		# update encounters labels
		if "encounters" in keys:
			if l == self.label_encounters:
				# if tile has encounter, update label text
				if self.data.encounters.ready.size() > 0:
					var new_text = "!"
					l.text = new_text
				else:
					l.text = ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# init color
	_update_color(self.data)
	# init label text
	_update_label_text(self.data)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# update label text/color if data changes
	_update_color(self.data)
	_update_label_text(self.data)
