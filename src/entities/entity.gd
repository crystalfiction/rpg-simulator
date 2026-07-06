class_name Entity extends Node2D

# components
var Type: EntityType
enum EntityType {
	WORLD,
	TERRAIN,
	TILE,
	PLAYER,
	ENEMY,
	ITEM,
}

var data: Dictionary = {
	"uid": 0,
	"controller": "",
	# subclass data...
}


func get_entity_type() -> EntityType:
	return self.Type


func get_entity_type_string() -> String:
	var type_s = self.EntityType.find_key(self.Type)
	return type_s


## traverse data dictionary recursively
func _traverse_data(base: Dictionary, layer: Dictionary) -> Dictionary:
	for k in layer:
		if k is Dictionary:
			_traverse_data(base, base[k])
		else:
			base[k] = layer[k]
	return base
