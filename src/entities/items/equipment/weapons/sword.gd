class_name SwordWeapon extends Weapon

# components
var sword_data = {
	"stats": {
		"damage": 5
	}
}

## initializes the entity data
func _init() -> void:
	self.Class = WeaponClass.SWORD
	super ()
	_traverse_data(self.data, self.sword_data)