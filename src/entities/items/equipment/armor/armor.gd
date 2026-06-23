class_name Armor extends Equipment

# components
var Slot: ArmorSlot
enum ArmorSlot {
	HEAD,
	CHEST,
	LEGS,
	FEET
}
static var armor_slots: Dictionary = {
	0: HeadArmor,
	1: ChestArmor,
	2: LegArmor,
	3: FeetArmor
}

var armor_data = {
    "slot": Slot,
}

## initializes the entity data
func _init() -> void:
	self.EquipType = EquipmentType.ARMOR
	super()
	_traverse_data(self.data, self.armor_data)