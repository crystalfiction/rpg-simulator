extends Control

# refs
var world: Sprite2D
var Utils: Node
var FileLogger: Node

# components
@export var world_stats: GridContainer
@export var player_stats: GridContainer
@export var player_abilities: GridContainer
@export var player_developments: GridContainer
@export var enemy_stats: GridContainer

var label_settings: LabelSettings
var labels = []
var label_entry = {
	"obj": null, # source object
	"path": "", # data path
	"name": null, # name label
	"data": null, # data label
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


## checks for existing labels given the passed obj,
## and returns [bool, [labels]] depending on existence
func _check_obj_labels(obj: Variant, curr_labels: Array) -> Array:
	if is_instance_valid(obj):
		if !obj.is_queued_for_deletion():
			var found = curr_labels.filter(func(l): return l.obj == obj)
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

				curr_labels.append(new_label_entry)


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
		if curr_entry is Dictionary:
			# append path before traversing deeper
			curr_path += "."
			_traverse_make(obj, curr_entry, container, curr_labels, curr_path)
		else:
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

	self[container].add_child(new_name_label)
	self[container].add_child(new_data_label)

	curr_labels.append(new_label_entry)


## makes stat labels in the given stat container for the passed object
## and adds label entries to labels reference array
func _make_stat_labels(obj: Variant, container: String, curr_labels: Array):
	# filter object data
	var data_filtered = obj.data.duplicate()
	if obj is Player:
		var player_filters = [
			"uid",
			"controller",
			"world",
			"inventory"
		]
		for key in player_filters:
			data_filtered.erase(key)

	# traverse data dict and make labels
	_traverse_make(obj, data_filtered, container, curr_labels)


## handles the creation of world data labels
func _handle_world_panel(curr_world: Sprite2D, curr_labels: Array):
	if is_instance_valid(curr_world):
		if not curr_world.is_queued_for_deletion():
			# world
			var world_labels = _check_obj_labels(curr_world, curr_labels).front()
			# if no labels,
			if not world_labels:
				# make them
				_make_stat_labels(curr_world, "world_stats", curr_labels)

			# terrain
			if "terrain" in curr_world.data:
				# check for existing labels
				var terrain_labels = _check_obj_labels(curr_world.data.terrain, curr_labels).front()
				# if no labels,
				if not terrain_labels:
					# make them
					_make_stat_labels(curr_world.data.terrain, "world_stats", curr_labels)
				
				# biome
				if "biome" in curr_world.data.terrain.data:
					var biome_labels = _check_obj_labels(
						curr_world.data.terrain.data.biome, curr_labels).front()
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
			var player_labels = _check_obj_labels(p, curr_labels)
			var is_player_labels = player_labels.front()
			# if no labels,
			if not is_player_labels:
				# make player name label
				var new_name_label = Label.new()
				new_name_label.add_theme_font_override(
					"font", preload("res://src/assets/JetBrainsMono-Medium.ttf"))
				new_name_label.add_theme_font_size_override("font_size", 14)
				new_name_label.text = p.name
				# make empty label since 2 grid cols
				var new_empty_label = Label.new()
				self.player_stats.add_child(new_name_label)
				self.player_stats.add_child(new_empty_label)

				# make stat labels
				_make_stat_labels(p, "player_stats", curr_labels)

				# make abilities panel
				_make_abilities_labels(p, "player_abilities", curr_labels)


## handles the creation of enemy data labels
func _handle_enemy_panel(curr_enemies: Array, curr_labels: Array):
	# if enemies exist,
	if not curr_enemies.is_empty():
		# for each enemy,
		for e in curr_enemies:
			# if enemy is valid,
			if is_instance_valid(e):
				# and if not queued for deletion,
				if not e.is_queued_for_deletion():
					var enemy_labels = _check_obj_labels(e, curr_labels)
					var is_enemy_labels = enemy_labels.front()
					# if no labels,
					if not is_enemy_labels:
						# make enemy name label
						var new_name_label = Label.new()
						new_name_label.add_theme_font_override(
							"font", preload("res://src/assets/JetBrainsMono-Medium.ttf"))
						new_name_label.add_theme_font_size_override("font_size", 14)
						new_name_label.text = e.name
						# make empty label since 2 grid cols
						var new_empty_label = Label.new()
						self.enemy_stats.add_child(new_name_label)
						self.enemy_stats.add_child(new_empty_label)
						# make stat labels
						_make_stat_labels(e, "enemy_stats", curr_labels)
	
	# enemies array empty,
	else:
		# delete lingering name labels
		var children = self.enemy_stats.get_children()
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
				entry_data = entry_data.new()

			# update label entry data
			entry_data = entry_data[k]

		# update data label text with result
		entry.data.text = str(entry_data)


## updates all labels existing in the passed labels array
func _update_label_entries(curr_labels: Array):
	# for each label entry,
	for l in curr_labels:
		_update_entry(l)


func _process(_delta: float) -> void:
	# check for invalid labels
	if not self.labels.is_empty():
		_remove_invalids(self.labels)

	# handle object label creation
	_handle_world_panel(self.world, self.labels)
	_handle_player_panel(self.world.data.player, self.labels)
	var enemy_controller = self.world.data.controller.enemy_controller
	var enemies = enemy_controller.enemies
	_handle_enemy_panel(enemies, self.labels)

	# update label data
	_update_label_entries(self.labels)
