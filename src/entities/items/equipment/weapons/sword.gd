class_name Sword extends Weapon

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
	for k in self.sword_data:
		if k is Dictionary:
			for k_n in self.sword_data[k]:
				self.data[k][k_n] = sword_data[k][k_n]
		else:
			self.data[k] = sword_data[k]