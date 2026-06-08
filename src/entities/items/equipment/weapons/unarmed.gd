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
	for k in self.unarmed_data:
		if k is Dictionary:
			for k_n in self.unarmed_data[k]:
				self.data[k][k_n] = unarmed_data[k][k_n]
		else:
			self.data[k] = unarmed_data[k]