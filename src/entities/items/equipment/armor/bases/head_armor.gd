class_name HeadArmor extends Armor

# components
var head_armor_data = {
    "stats": {
        "armor": 5
    }
}

## initializes the entity data
func _init() -> void:
	self.Slot = ArmorSlot.HEAD
	super()
	_traverse_data(self.data, self.head_armor_data)