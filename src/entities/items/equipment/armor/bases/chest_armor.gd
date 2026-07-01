class_name ChestArmor extends Armor

# components
var chest_armor_data = {
    "stats": {
        "armor": 10
    }
}

## initializes the entity data
func _init() -> void:
	self.Slot = ArmorSlot.CHEST
	super()
	_traverse_data(self.data, self.chest_armor_data)
