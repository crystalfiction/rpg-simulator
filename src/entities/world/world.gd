class_name World extends Entity

# refs

# components
var data = {
	"uid": 0,
	"controller": "",
	"terrain": {
		"grid": [], # [[ Vector2i(x, y) ]]
		"tile_map": [], # [[ Tile<Sprite2D> ]]
		"map_complete": false,
		"map_count": 0,
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