class_name Staff extends Weapon

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
	for k in self.staff_data:
		if k is Dictionary:
			for k_n in self.staff_data[k]:
				self.data[k][k_n] = staff_data[k][k_n]
		else:
			self.data[k] = staff_data[k]