class_name Weapon extends Equipment

# components
var Class: WeaponClass
enum WeaponClass {
	UNARMED,
	SWORD,
	BOW,
	STAFF,
}
static var WeaponClasses = {
	0: UnarmedWeapon,
	1: SwordWeapon,
	2: BowWeapon,
	3: StaffWeapon
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
	self.EquipType = EquipmentType.WEAPON
	super()
	_traverse_data(self.data, self.weapon_data)