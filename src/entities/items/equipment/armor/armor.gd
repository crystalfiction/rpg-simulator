class_name Armor extends Equipment

# components
var Slot: ArmorSlot
enum ArmorSlot {
	CHEST,
}

var armor_data = {
    "slot": Slot,
}

## initializes the entity data
func _init() -> void:
	self.EquipType = EquipmentType.ARMOR
	super ()
	_traverse_data(self.data, self.armor_data)