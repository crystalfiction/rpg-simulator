class_name BowWeapon extends Weapon

# components
var bow_data = {
	"stats": {
		"damage": 5
	}
}

## initializes the entity data
func _init() -> void:
	self.Class = WeaponClass.BOW
	super ()
	_traverse_data(self.data, self.bow_data)