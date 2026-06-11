class_name World extends Entity

# components
var init_world: Resource = preload("res://src/entities/world/world.tscn")
var init_data: Dictionary = {
	"terrain": {},
}


## initializes the scene
func init_scene() -> Sprite2D:
	var new_scene = self.init_world.instantiate()
	return new_scene

## initializes the entity
func _init() -> void:
	self.Type = EntityType.WORLD
	for k in self.init_data:
		self.data[k] = init_data[k]