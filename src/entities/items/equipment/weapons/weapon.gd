class_name Weapon extends Equipment

# components
var Class: WeaponClass
enum WeaponClass {
	UNARMED,
	SWORD,
	BOW,
	STAFF,
}

var weapon_data = {
	"stats": {
		"damage": 0,
	}
}


## gets and returns the weapon's class string
func get_weapon_class_string() -> String:
	var key = WeaponClass.find_key(self.Class)
	return key

## initializes the entity data
func _init() -> void:
	self.Slot = EquipmentSlot.WEAPON
	super ()
	for k in self.weapon_data:
		self.data[k] = weapon_data[k]