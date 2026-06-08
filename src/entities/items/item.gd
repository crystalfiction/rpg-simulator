class_name Item extends Entity

# components
var Use: ItemUse
enum ItemUse {
    EQUIP,
}

var item_data = {
    "use": Use,
}


## initializes the entity data
func _init() -> void:
	self.Type = EntityType.ITEM
	for k in self.item_data:
		self.data[k] = item_data[k]