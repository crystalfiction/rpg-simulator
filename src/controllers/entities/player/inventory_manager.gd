class_name InventoryManager extends RefCounted

# refs
var entity: Entity
var items: Array = [] # backpack items


## called on script initialization
func _init(new_entity: Entity) -> void:
	self.entity = new_entity


## adds an item to the inventory backpack
func add_item(item: Item) -> bool:
	if item == null:
		return false
	items.append(item)
	return true


## removes an item from the inventory backpack by reference
func remove_item(item: Item) -> bool:
	if item == null or item not in items:
		return false
	items.erase(item)
	return true


## removes item at index from backpack
func remove_item_at(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	items.remove_at(index)
	return true


## equips an equipment item to the appropriate slot
func equip_item(item: Equipment) -> bool:
	if item == null or not item is Equipment:
		return false
	
	# determine slot based on equipment type
	match item.EquipType:
		Equipment.EquipmentType.WEAPON:
			# unequip existing weapon first
			if entity.data.inventory.equipped.weapon != null:
				unequip_item(Equipment.EquipmentType.WEAPON)
			entity.data.inventory.equipped.weapon = item
			return true
		
		Equipment.EquipmentType.ARMOR:
			# determine armor slot
			if item is Armor:
				match item.Slot:
					Armor.ArmorSlot.HEAD:
						if entity.data.inventory.equipped.head != null:
							unequip_item_from_slot("head")
						entity.data.inventory.equipped.head = item
						# add value to armor stat
						entity.data.stats.armor += item.data.stats.armor
						return true
					Armor.ArmorSlot.CHEST:
						if entity.data.inventory.equipped.chest != null:
							unequip_item_from_slot("chest")
						entity.data.inventory.equipped.chest = item
						# add value to armor stat
						entity.data.stats.armor += item.data.stats.armor
						return true
					Armor.ArmorSlot.LEGS:
						if entity.data.inventory.equipped.legs != null:
							unequip_item_from_slot("legs")
						entity.data.inventory.equipped.legs = item
						# add value to armor stat
						entity.data.stats.armor += item.data.stats.armor
						return true
					Armor.ArmorSlot.FEET:
						if entity.data.inventory.equipped.feet != null:
							unequip_item_from_slot("feet")
						entity.data.inventory.equipped.feet = item
						# add value to armor stat
						entity.data.stats.armor += item.data.stats.armor
						return true
			return false
	
	return false


## unequips equipment from a slot by equipment type
func unequip_item(
	equip_type: Equipment.EquipmentType,
	slot_name: Armor.ArmorSlot
) -> Equipment:
	match equip_type:
		Equipment.EquipmentType.WEAPON:
			var unequipped = entity.data.inventory.equipped.weapon
			entity.data.inventory.equipped.weapon = null
			return unequipped
		Equipment.EquipmentType.ARMOR:
			match slot_name:
				Armor.ArmorSlot.HEAD:
					var unequipped = entity.data.inventory.equipped.head
					entity.data.inventory.equipped.head = null
					return unequipped
				Armor.ArmorSlot.CHEST:
					var unequipped = entity.data.inventory.equipped.chest
					entity.data.inventory.equipped.chest = null
					return unequipped
				Armor.ArmorSlot.LEGS:
					var unequipped = entity.data.inventory.equipped.legs
					entity.data.inventory.equipped.legs = null
					return unequipped
				Armor.ArmorSlot.FEET:
					var unequipped = entity.data.inventory.equipped.feet
					entity.data.inventory.equipped.feet = null
					return unequipped
	return null


## unequips equipment from a specific slot name
func unequip_item_from_slot(slot_name: String) -> Equipment:
	if slot_name in entity.data.inventory.equipped:
		var unequipped = entity.data.inventory.equipped[slot_name]
		entity.data.inventory.equipped[slot_name] = null
		return unequipped
	
	return null


## gets currently equipped item from slot
func get_equipped(slot_name: String) -> Equipment:
	if slot_name in entity.data.inventory.equipped:
		return entity.data.inventory.equipped[slot_name]
	return null


## returns all backpack items
func get_items() -> Array:
	return items.duplicate()


## returns count of items in backpack
func get_item_count() -> int:
	return items.size()


## finds first item matching the given type name in backpack
func find_item_by_type(type_name: String) -> Item:
	for item in items:
		if item.get_class() == type_name:
			return item
	return null


## reorders item in backpack (move from index to new index)
func reorder_item(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= items.size():
		return false
	if to_index < 0 or to_index >= items.size():
		return false
	
	var item = items[from_index]
	items.remove_at(from_index)
	items.insert(to_index, item)
	return true
