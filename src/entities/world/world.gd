class_name World extends Entity

# components
var data: Dictionary
var init_data = {
	"uid": 0,
	"controller": "",
	"terrain": {
		"grid": [], # [[ Vector2i(x, y) ]]
		"tile_map": [], # [[ Tile<Sprite2D> ]]
		"weather": {
			"tile_map": [],
		},
		"resources": {
			"tile_map": [],
			"count": 0
		},
		"encounters": {
			"tile_map": [],
			"count": 0
		}
	},
}

# when World ready,
func _ready() -> void:
	# init entity data structure to avoid null errors on dependents
	self.data = self.init_data