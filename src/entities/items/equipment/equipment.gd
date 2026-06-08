class_name Equipment extends Item

# components
var Slot: EquipmentSlot
enum EquipmentSlot {
	WEAPON,
	ARMOR
}

var equipment_data = {
	"slot": Slot
}

## initializes the entity data
func _init() -> void:
	self.Use = ItemUse.EQUIP
	super ()
	for k in self.equipment_data:
		self.data[k] = equipment_data[k]
