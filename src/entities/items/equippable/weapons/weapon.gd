class_name Weapon extends EquippableItem

# components
var Class: WeaponClass
enum WeaponClass {
    SWORD
}


func _init(weapon_class: WeaponClass) -> void:
    self.Equipment = EquipmentType.WEAPON
    self.Class = weapon_class