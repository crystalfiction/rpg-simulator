class_name LegArmor extends Armor

# components
var leg_armor_data = {
    "stats": {
        "armor": 20
    }
}

## initializes the entity data
func _init() -> void:
	self.Slot = ArmorSlot.LEGS
	super()
	_traverse_data(self.data, self.leg_armor_data)