extends Control

# refs
var world: Sprite2D
var Utils: Node
var FileLogger: Node

# components
@export var world_stats: GridContainer
@export var player_vitals: GridContainer
@export var player_combat_vitals: GridContainer
@export var player_stats: GridContainer
@export var player_abilities: GridContainer
@export var player_equipped: GridContainer
@export var player_bags: GridContainer
@export var enemy_combat_vitals: GridContainer

var label_settings: LabelSettings
var labels = []
var label_entry = {
	"obj": null, # source object
	"path": "", # data path
	"name": null, # name label
	"data": null, # data label
	"container": null, # object container
}

var label_filters = {
	"world": [
		"uid",
		"controller",
	],
	"terrain": [
		"uid",
		"controller",
		"on_change",
		"grid",
		"tile_map",
		"biome",
	],
	"biome": [
		"class"
	],
	"player": [
		"uid",
		"controller",
		"world",
		"class",
		"stats.base_health",
		"stats.base_attack",
		"stats.armor_factor",
		"stats.base_crit",
		"stats.base_dodge",
		"actions.controller",
		"actions.action",
		"actions.abilities",
		"encounters.active",
		"inventory.controller",
		"inventory.equipped.weapon",
		"inventory.equipped.head",
		"inventory.equipped.chest",
		"inventory.equipped.legs",
		"inventory.equipped.feet",
		"inventory.bags",
		"inventory.items"
	],
	"enemy": [
		"uid",
		"controller",
		"world",
		"stats.base_health",
		"stats.base_attack",
		"stats.base_crit",
		"stats.base_dodge",
		"actions.controller",
		"actions.action",
		"actions.abilities",
		"encounters.active",
		"inventory.controller",
		"inventory.bag"
	]
}

var string_n := 12


func _get_substring(string: String, n: int) -> String:
	var substring = ""
	substring = string if string.length() <= string_n else string.substr(0, n) + "..."
	return substring


## removes labels and label entries with invalid objects
func _remove_invalids(curr_labels: Array):
	# remove labels if player invalid
	var invalids = curr_labels.filter(
		func(l): return (
			not is_instance_valid(l.obj) or
			not is_instance_valid(l.name) or
			not is_instance_valid(l.data))
	)
	if not invalids.is_empty():
		for invalid in invalids:
			# remove name label
			if is_instance_valid(invalid.name):
				if not invalid.name.is_queued_for_deletion():
					invalid.name.queue_free()
			# remove data label
			if is_instance_valid(invalid.data):
				if not invalid.data.is_queued_for_deletion():
					invalid.data.queue_free()
			# remove label entry ref
			curr_labels.erase(invalid)


## checks for existing labels given the passed obj and container,
## and returns [bool, [labels]] depending on existence
func _check_obj_labels(obj: Variant, container: String, curr_labels: Array) -> Array:
	if is_instance_valid(obj):
		if !obj.is_queued_for_deletion():
			var found = curr_labels.filter(
				func(l): return l.obj == obj && l.container == container)
			if found.size() == 0:
				return [false, ]
			else:
				return [true, found]
	return [false, ]


## creates player abilities panel given the passed player and container,
## then adds to labels array for data updating
func _make_abilities_labels(p: Player, container: String, curr_labels: Array):
	var abilities = p.data.actions.abilities
	for atk in abilities:
		# make new attack name label
		var attack_name = atk.get_global_name()
		var new_title_label = Label.new()
		new_title_label.name = attack_name
		new_title_label.text = attack_name
		new_title_label.add_theme_font_override(
			"font", preload("res://src/assets/JetBrainsMono-Medium.ttf"))
		new_title_label.add_theme_font_size_override("font_size", 14)
		# make empty label to pass 2nd grid col
		var empty_label = Label.new()
		empty_label.name = "Pass"
		empty_label.label_settings = self.label_settings

		self[container].add_child(new_title_label)
		self[container].add_child(empty_label)
		
		var data_filters = [
			"multiplier",
			"cooldown",
			"duration"
		]
		var attack_data = atk.new().data
		for key in attack_data:
			if key in data_filters:
				var new_name_label = Label.new()
				new_name_label.name = key
				new_name_label.text = key
				new_name_label.label_settings = self.label_settings

				var new_data_label = Label.new()
				new_data_label.name = key + "_data"
				new_data_label.text = str(attack_data[key])
				new_data_label.label_settings = self.label_settings

				self[container].add_child(new_name_label)
				self[container].add_child(new_data_label)

				var new_label_entry = self.label_entry.duplicate()
				new_label_entry.obj = p
				var path = "actions.abilities." + str(p.data.actions.abilities.find(atk)) + ".data." + key
				new_label_entry.path = path
				new_label_entry.name = new_name_label
				new_label_entry.data = new_data_label
				new_label_entry.container = container
				curr_labels.append(new_label_entry)


## creates combat entity vitals in combat UI panel
func _make_entity_vitals(entity: Entity, container: String, curr_labels: Array):
	# make player name label
	var new_name_label = Label.new()
	new_name_label.add_theme_font_override(
		"font", preload("res://src/assets/JetBrainsMono-Medium.ttf"))
	# new_name_label.add_theme_font_size_override("font_size", 14)
	new_name_label.text = entity.name
	new_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	self[container].add_child(new_name_label)

	# level label
	var new_level_label = Label.new()
	new_level_label.add_theme_font_override(
		"font", preload("res://src/assets/JetBrainsMono-Medium.ttf"))
	new_level_label.add_theme_font_size_override("font_size", 14)
	new_level_label.text = str(entity.data.stats.level)
	self[container].add_child(new_level_label)

	var new_level_entry = self.label_entry.duplicate()
	new_level_entry.obj = entity
	new_level_entry.path = "stats.level"
	new_level_entry.name = new_level_label
	new_level_entry.data = new_level_label
	new_level_entry.container = container
	curr_labels.append(new_level_entry)

	# health bar
	var new_health_bar = ProgressBar.new()
	new_health_bar.value = entity.data.stats.health
	new_health_bar.max_value = entity.data.stats.max_health
	new_health_bar.show_percentage = false
	new_health_bar.custom_minimum_size = Vector2(0, 8) # bar height
	var health_fill = StyleBoxFlat.new()
	health_fill.bg_color = Color(0.471, 0.631, 0.314) # fill color
	new_health_bar.add_theme_stylebox_override("fill", health_fill)
	self[container].add_child(new_health_bar)
	
	var health_bar_entry = self.label_entry.duplicate()
	health_bar_entry.obj = entity
	health_bar_entry.path = "stats.health"
	health_bar_entry.name = new_health_bar
	health_bar_entry.data = new_health_bar
	health_bar_entry.container = container
	curr_labels.append(health_bar_entry)

	# make additional entry to update health max_value
	var health_bar_max = self.label_entry.duplicate()
	health_bar_max.obj = entity
	health_bar_max.path = "stats.max_health"
	health_bar_max.name = new_health_bar
	health_bar_max.data = new_health_bar
	health_bar_max.container = container
	curr_labels.append(health_bar_max)
	
	# exp bar
	if "exp" in entity.data.stats:
		var new_exp_bar = ProgressBar.new()
		new_exp_bar.value = entity.data.stats.exp
		new_exp_bar.max_value = entity.data.stats.exp_cap
		new_exp_bar.show_percentage = false
		new_exp_bar.custom_minimum_size = Vector2(0, 6) # bar height
		var exp_fill = StyleBoxFlat.new()
		exp_fill.bg_color = Color(0.314, 0.541, 0.631) # fill color
		new_exp_bar.add_theme_stylebox_override("fill", exp_fill)
		self[container].add_child(new_exp_bar)

		var exp_bar_entry = self.label_entry.duplicate()
		exp_bar_entry.obj = entity
		exp_bar_entry.path = "stats.exp"
		exp_bar_entry.name = new_exp_bar
		exp_bar_entry.data = new_exp_bar
		exp_bar_entry.container = container
		curr_labels.append(exp_bar_entry)

		# make additional entry to update exp max_value
		var exp_bar_max = self.label_entry.duplicate()
		exp_bar_max.obj = entity
		exp_bar_max.path = "stats.exp_cap"
		exp_bar_max.name = new_exp_bar
		exp_bar_max.data = new_exp_bar
		exp_bar_max.container = container
		curr_labels.append(exp_bar_max)


## handles creation of inventory equipment view
func _make_inventory_equipped(p: Player, curr_labels: Array):
	var equipped: Dictionary = p.data.inventory.equipped
	for key in equipped:
		# make name/item labels
		var curr_slot = equipped[key]
		var path = "inventory.equipped." + key
		_make_stat_label(
			p, key, path, curr_slot,
			"player_equipped", curr_labels)


## handles creation of inventory bags view
func _make_inventory_bags(p: Player, curr_labels: Array):
	var bags: Array = p.data.inventory.bags
	var i = 0
	if not bags.is_empty():
		for item in bags:
			var obj_labels = _check_obj_labels(p, "player_bags", curr_labels)
			var is_obj_labels = obj_labels[0]
			var path = "inventory.bags." + str(i)
			# if no obj labels,
			if not is_obj_labels:
				# make labels
					_make_stat_label(
						p, str(i), path, item,
						"player_bags", curr_labels)
			
			# if obj labels,
			else:
				# check if current bag slot label exists
				var label_paths = []
				for l in obj_labels[1]:
					label_paths.append(l.path)

				if path not in label_paths:
					# make item stat label
					_make_stat_label(
						p, str(i), path, item,
						"player_bags", curr_labels)
					
			# increment index
			i += 1


## recursively traverses obj data dictionaries and creates labels
## for non-dictionary data types
func _traverse_make(
	obj: Variant,
	data: Dictionary,
	container: String,
	curr_labels: Array,
	path: String = ""
):
	for key in data:
		var curr_entry = data[key]
		var curr_path = path + str(key)
		# if entry is dictionary,
		if curr_entry is Dictionary:
			# append path before traversing deeper
			curr_path += "."
			_traverse_make(obj, curr_entry, container, curr_labels, curr_path)
		
		# end of nest,
		else:
			# data label filtering
			if obj is World:
				if curr_path not in self.label_filters.world:
					# make labels
					_make_stat_label(obj, key, curr_path, curr_entry, container, curr_labels)
			elif obj is Terrain:
				if curr_path not in self.label_filters.terrain:
					# make labels
					_make_stat_label(obj, key, curr_path, curr_entry, container, curr_labels)
			elif obj is Biome:
				if curr_path not in self.label_filters.biome:
					# make labels
					_make_stat_label(obj, key, curr_path, curr_entry, container, curr_labels)
			elif obj is Player:
				if curr_path not in self.label_filters.player:
					# make labels
					_make_stat_label(obj, key, curr_path, curr_entry, container, curr_labels)
			elif obj is Enemy:
				if curr_path not in self.label_filters.enemy:
					# make labels
					_make_stat_label(obj, key, curr_path, curr_entry, container, curr_labels)
			# no filtering,
			else:
				# make labels
				_make_stat_label(obj, key, curr_path, curr_entry, container, curr_labels)


## makes name and data ui labels for data entry 
## and adds ref to labels array
func _make_stat_label(
	obj: Variant,
	key: String,
	path: String,
	data: Variant,
	container: String,
	curr_labels: Array
):
	# name label
	var new_name_label = Label.new()
	new_name_label.label_settings = self.label_settings
	new_name_label.name = key
	new_name_label.text = path
	# force width clipping
	new_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_name_label.custom_minimum_size.x = 128
	
	# data label
	var new_data_label = Label.new()
	new_data_label.label_settings = self.label_settings
	new_data_label.name = key + "_data"
	# stringify data
	new_data_label.text = str(data)
	# force width clipping
	new_data_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_data_label.custom_minimum_size.x = 128

	# label entry ref
	var new_label_entry = self.label_entry.duplicate()
	new_label_entry.obj = obj
	new_label_entry.path = path
	new_label_entry.name = new_name_label
	new_label_entry.data = new_data_label
	new_label_entry.container = container

	# add to tree
	self[container].add_child(new_name_label)
	self[container].add_child(new_data_label)

	# add to label entries ref
	curr_labels.append(new_label_entry)


## makes stat labels in the given stat container for the passed object
## and adds label entries to labels reference array
func _make_stat_labels(obj: Variant, container: String, curr_labels: Array):
	# traverse data dict and make labels
	_traverse_make(obj, obj.data, container, curr_labels)


## handles the creation of world data labels
func _handle_world_panel(curr_world: Sprite2D, curr_labels: Array):
	if is_instance_valid(curr_world):
		if not curr_world.is_queued_for_deletion():
			# world
			var world_labels = _check_obj_labels(curr_world, "world_stats", curr_labels).front()
			# if no labels,
			if not world_labels:
				# make them
				_make_stat_labels(curr_world, "world_stats", curr_labels)

			# terrain
			if "terrain" in curr_world.data:
				# check for existing labels
				var terrain_labels = _check_obj_labels(curr_world.data.terrain, "world_stats", curr_labels).front()
				# if no labels,
				if not terrain_labels:
					# make them
					_make_stat_labels(curr_world.data.terrain, "world_stats", curr_labels)
				
				# biome
				if "biome" in curr_world.data.terrain.data:
					var biome_labels = _check_obj_labels(
						curr_world.data.terrain.data.biome, "world_stats", curr_labels).front()
					# if no labels,
					if not biome_labels:
						# make them
						_make_stat_labels(curr_world.data.terrain.data.biome, "world_stats", curr_labels)


## handles the creation of player data labels
func _handle_player_panel(p: Player, curr_labels: Array):
	# if player is valid,
	if is_instance_valid(p):
		# and if not queued for deletion,
		if not p.is_queued_for_deletion():
			# vitals
			var vital_labels = _check_obj_labels(p, "player_vitals", curr_labels)
			var is_vital_labels = vital_labels.front()
			if not is_vital_labels:
				_make_entity_vitals(p, "player_vitals", curr_labels)
			
			# stats
			var stat_labels = _check_obj_labels(p, "player_stats", curr_labels)
			var is_stat_labels = stat_labels.front()
			if not is_stat_labels:
				# make stat labels
				_make_stat_labels(p, "player_stats", curr_labels)
			
			# abilities
			var ability_labels = _check_obj_labels(p, "player_abilities", curr_labels)
			var is_ability_labels = ability_labels.front()
			if not is_ability_labels:
				# make abilities panel
				_make_abilities_labels(p, "player_abilities", curr_labels)


## handles creation of player inventory panel
func _handle_inventory_panel(p: Player, curr_labels: Array):
	# if player is valid,
	if is_instance_valid(p):
		# and if not queued for deletion,
		if not p.is_queued_for_deletion():
			var equipped_labels = _check_obj_labels(p, "player_equipped", curr_labels)
			var is_equipped_labels = equipped_labels.front()
			if not is_equipped_labels:
				_make_inventory_equipped(p, curr_labels)
			
			# make bag labels
			_make_inventory_bags(p, curr_labels)


## handles the creation of the combat panel items such as combat vitals
func _handle_combat_panel(p: Player, enemies: Array, curr_labels: Array):
	# make player vitals
	# if player is valid,
	if is_instance_valid(p):
		# and if not queued for deletion,
		if not p.is_queued_for_deletion():
			# check if player combat vitals container empty before making
			var container_children = self.player_combat_vitals.get_children()
			if container_children.is_empty():
				_make_entity_vitals(p, "player_combat_vitals", curr_labels)
	
	# player invalid,
	else:
		# delete lingering labels
		var children = self.player_combat_vitals.get_children()
		for label in children:
			if is_instance_valid(label):
				if not label.is_queued_for_deletion():
					label.queue_free()

	# make enemy vitals
	if not enemies.is_empty():
		# for each enemy,
		for e in enemies:
			# if enemy is valid,
			if is_instance_valid(e):
				# and if not queued for deletion,
				if not e.is_queued_for_deletion():
					# check if enemy combat vitals container empty before making
					var container_children = self.enemy_combat_vitals.get_children()
					if container_children.is_empty():
						_make_entity_vitals(e, "enemy_combat_vitals", curr_labels)
	
	# enemies array empty,
	else:
		# delete lingering labels
		var children = self.enemy_combat_vitals.get_children()
		for label in children:
			if is_instance_valid(label):
				if not label.is_queued_for_deletion():
					label.queue_free()


func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"
	# get utils
	self.Utils = $"/root/Utils"

	# define label settings
	var new_stat_label_settings = LabelSettings.new()
	new_stat_label_settings.font = preload("res://src/assets/JetBrainsMono-Medium.ttf")
	new_stat_label_settings.font_size = 11
	self.label_settings = new_stat_label_settings # define label settings


## traverses label object data recursively until label entry key found, 
## and updates data label text with result
func _update_entry(entry: Dictionary):
	# split key path
	var keys = entry.path.split(".", false, 0)
	if not keys.is_empty():
		# step into dict according to key path
		var entry_data = entry.obj.data
		for k in keys:
			# account for array indexes
			if entry_data is Array && k.is_valid_int():
				k = int(k)
			
			# account for script objects
			if entry_data is GDScript:
				# spin up script for data
				entry_data = entry_data.new()
				# if attack,
				if entry_data is AttackAction:
					# define source for data calculations
					entry_data.data.src = entry.obj
					# if attack has multiplier,
					if entry_data.has_method("calculate_multiplier"):
						# calculate it
						entry_data.calculate_multiplier()
			
			# update label entry data
			entry_data = entry_data[k]

			# format entry data
			if is_instance_valid(entry_data):
				if entry_data is Armor or entry_data is Weapon:
					entry_data = entry_data.get_script().get_global_name()

		# determine what is being updated,
		if entry.data is Label:
			# update label text if label
			entry.data.text = str(entry_data)
		elif entry.data is ProgressBar:
			# check which bar is being updated,
			if (
				entry.path == "stats.exp_cap" or
				entry.path == "stats.max_health"
			):
				# update max value if exp cap
				entry.data.max_value = entry_data
			else:
				# otherwise update value
				entry.data.value = entry_data


## updates all labels existing in the passed labels array
func _update_label_entries(curr_labels: Array):
	# for each label entry,
	for l in curr_labels:
		_update_entry(l)


func _process(_delta: float) -> void:
	# check for invalid labels
	if not self.labels.is_empty():
		_remove_invalids(self.labels)

	# if world valid,
	if is_instance_valid(self.world):
		# handle world panel
		_handle_world_panel(self.world, self.labels)
		
		# if player valid,
		if is_instance_valid(self.world.data.player):
			# handle player panel
			_handle_player_panel(self.world.data.player, self.labels)

			# handle inventory panel
			_handle_inventory_panel(self.world.data.player, self.labels)
			
			# handle combat panel
			var enemy_controller = self.world.data.controller.enemy_controller
			var enemies = enemy_controller.enemies
			_handle_combat_panel(self.world.data.player, enemies, self.labels)

		# player invalid
		else:
			# remove invalid labels
			_remove_invalids(self.labels)
	
	# world invalid,
	else:
		# remove invalid labels
		_remove_invalids(self.labels)

	# update label data
	if not self.labels.is_empty():
		_update_label_entries(self.labels)
