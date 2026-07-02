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
		for i in invalids:
			# remove name label
			if is_instance_valid(invalids[i].name):
				if not invalids[i].name.is_queued_for_deletion():
					invalids[i].name.queue_free()
			# remove data label
			if is_instance_valid(invalids[i].data):
				if not invalids[i].data.is_queued_for_deletion():
					invalids[i].data.queue_free()
			# remove label entry ref
			invalids[i].erase()


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
func traverse_data(
	obj: Variant,
	key: String,
	data: Dictionary,
	container: String,
	curr_labels: Array
):
	for k in data:
		var entry = data[k]
		var key_fmt = key + "." + k
		if entry is Dictionary:
			traverse_data(obj, key_fmt, entry, container, curr_labels)
		else:
			_make_stat_label(obj, key_fmt, entry, container, curr_labels)


## makes name and data ui labels for data entry 
## and adds ref to labels array
func _make_stat_label(
	obj: Variant,
	key: String,
	data: Variant,
	container: String,
	curr_labels: Array
):
	# name label
	var new_name_label = Label.new()
	new_name_label.label_settings = self.label_settings
	if obj is Terrain:
		key = "terrain." + key
	elif obj is Biome:
		key = "biome." + key
	new_name_label.name = key
	new_name_label.text = key
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


func _make_stat_labels(obj: Variant, container: String, curr_labels: Array):
	var player_filters = [
		"stats",
		"resources",
		"inventory",
	]
	
	var data = obj.data
	for k in data:
		if (
			obj is World ||
			obj is Terrain ||
			obj is Biome ||
			(obj is Player && k in player_filters)
		):
			var entry = data[k]
			# if entry is a dictionary,
			if entry is Dictionary:
				# traverse dictionary entry recursively
				traverse_data(obj, k, entry, container, curr_labels)
			
			# not dictionary,
			else:
				# make label for entry
				_make_stat_label(obj, k, entry, container, curr_labels)


func _handle_world_stats(curr_world: Sprite2D, curr_labels: Array):
	if is_instance_valid(curr_world):
		if not curr_world.is_queued_for_deletion():
			# world
			var world_labels = _check_obj_labels(curr_world, curr_labels).front()
			if not world_labels:
				_make_stat_labels(curr_world, "world_stats", curr_labels)

			# terrain
			if "terrain" in curr_world.data:
				# check for existing labels
				var terrain_labels = _check_obj_labels(curr_world.data.terrain, curr_labels).front()
				if not terrain_labels:
					# make labels if none
					_make_stat_labels(curr_world.data.terrain, "world_stats", curr_labels)
				
				# biome
				if "biome" in curr_world.data.terrain.data:
					var biome_labels = _check_obj_labels(
						curr_world.data.terrain.data.biome, curr_labels).front()
					if not biome_labels:
						_make_stat_labels(curr_world.data.terrain.data.biome, "world_stats", curr_labels)


func _handle_party_stats(curr_party: Dictionary, curr_labels: Array):
	var members = curr_party.members
	if not members.is_empty():
		for p in members:
			# player is valid,
			if is_instance_valid(p):
				if not p.is_queued_for_deletion():
					var player_labels = _check_obj_labels(p, curr_labels).front()
					if not player_labels:
						_make_stat_labels(p, "party_stats", curr_labels)


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


func _process(_delta: float) -> void:
	if not self.labels.is_empty():
		_remove_invalids(self.labels)

	_handle_world_stats(self.world, self.labels)
	_handle_party_stats(self.world.data.party, self.labels)
