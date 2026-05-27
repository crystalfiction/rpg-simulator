class_name World extends Entity

# components
var data = {
	"uid": 0,
	"controller": "",
	"terrain": {
		"grid": [], # [[ Vector2i(x, y) ]]
		"tile_map": [], # [[ Tile<Sprite2D> ]]
	},
	"resources": [],
	## TODO: encounters
}
