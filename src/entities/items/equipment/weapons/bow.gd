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
	for k in self.bow_data:
		if k is Dictionary:
			for k_n in self.bow_data[k]:
				self.data[k][k_n] = bow_data[k][k_n]
		else:
			self.data[k] = bow_data[k]