class_name World extends Entity

# for reference
var init_data = {
	# "uid": 0,
	# "controller": "",
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

## define entity class data before instantiation
func _init() -> void:
	pass