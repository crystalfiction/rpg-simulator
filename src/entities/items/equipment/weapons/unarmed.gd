class_name UnarmedWeapon extends Weapon

# components
var unarmed_data = {
	"stats": {
		"damage": 0
	}
}

## initializes the entity data
func _init() -> void:
	self.Class = WeaponClass.UNARMED
	super ()
	_traverse_data(self.data, self.unarmed_data)