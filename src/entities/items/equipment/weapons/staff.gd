class_name StaffWeapon extends Weapon

# components
var staff_data = {
	"stats": {
		"damage": 5
	}
}

## initializes the entity data
func _init() -> void:
	self.Class = WeaponClass.STAFF
	super ()
	_traverse_data(self.data, self.staff_data)