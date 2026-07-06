extends Control

# refs
var world: Sprite2D
var Utils: Node
var FileLogger: Node

# components
@export var world_stats: GridContainer
@export var party_stats: GridContainer
@export var enemy_stats: GridContainer

var label_settings: LabelSettings
var labels = []
var label_entry = {
	"obj": null, # source object
	"key": "", # data key
	"name": null, # name label
	"data": null, # data label
}
var label_filters = {
	"world": [],
	"player": [
		"class_V",
		"stats",
		"skills",
		"resources",
		"inventory"
	],
	"enemy": []
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
		func(l): return not is_instance_valid(l.obj)
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
	new_label_entry.key = key
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
			"controller",
			"world",
			"actions",
			"encounters"
		]
		for key in player_filters:
			data_filtered.erase(key)

	# traverse data dict and make labels
	_traverse_make(obj, data_filtered, container, curr_labels)


## handles the creation of world data labels
func _handle_world_stats(curr_world: Sprite2D, curr_labels: Array):
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


## handles the creation of party data labels
func _handle_party_stats(curr_party: Dictionary, curr_labels: Array):
	var members = curr_party.members
	# if party members exist,
	if not members.is_empty():
		# for each party member,
		for p in members:
			# if player is valid,
			if is_instance_valid(p):
				# and if not queued for deletion,
				if not p.is_queued_for_deletion():
					var player_labels = _check_obj_labels(p, curr_labels)
					var is_player_labels = player_labels.front()
					# if no labels,
					if not is_player_labels:
						# make them
						_make_stat_labels(p, "party_stats", curr_labels)


func _handle_enemy_stats(curr_enemies: Array, curr_labels: Array):
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
						# make them
						_make_stat_labels(e, "enemy_stats", curr_labels)
	
	# enemies array empty,
	else:
		# delete all enemy labels
		pass


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
func _traverse_update(entry: Dictionary, data: Variant):
	if data is Dictionary:
		for key in data:
			# if entry key found,
			if key == entry.key:
				# update data label text and return
				entry.data.text = str(data[key])
				return
			
			# continue traversing data until found
			_traverse_update(entry, data[key])


## updates all labels existing in the passed labels array
func _update_label_entries(curr_labels: Array):
	# for each label entry,
	for l in curr_labels:
		_traverse_update(l, l.obj.data)


func _process(_delta: float) -> void:
	# check for invalid labels
	if not self.labels.is_empty():
		_remove_invalids(self.labels)

	# handle object label creation
	_handle_world_stats(self.world, self.labels)
	_handle_party_stats(self.world.data.party, self.labels)
	var enemy_controller = self.world.data.controller.enemy_controller
	var enemies = enemy_controller.enemies
	_handle_enemy_stats(enemies, self.labels)

	# update label data
	_update_label_entries(self.labels)
