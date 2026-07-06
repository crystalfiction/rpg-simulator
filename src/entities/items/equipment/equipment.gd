class_name Equipment extends Item

# components
var EquipType: EquipmentType
enum EquipmentType {
	WEAPON,
	ARMOR
}

var equipment_data = {
	"equip_type": EquipType
}


func get_equipment_type() -> EquipmentType:
	return self.EquipType


func get_equipment_type_string() -> String:
	var type = self.EquipType
	return self.EquipmentType.find_key(type)


## initializes the entity data
func _init() -> void:
	self.Use = ItemUse.EQUIP
	super()
	_traverse_data(self.data, self.equipment_data)