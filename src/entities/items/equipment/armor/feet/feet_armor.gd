class_name FeetArmor extends Armor

# components
var feet_armor_data = {
    "stats": {
        "armor": 10
    }
}

## initializes the entity data
func _init() -> void:
	self.Slot = ArmorSlot.FEET
	super()
	_traverse_data(self.data, self.feet_armor_data)