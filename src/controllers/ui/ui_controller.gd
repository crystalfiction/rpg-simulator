extends Control

# references
var world: World
var FileLogger

# components
var stat_label_settings: LabelSettings
var log_label_settings: LabelSettings

@export var world_stats: GridContainer
@export var enemy_stats: GridContainer
@export var player_class: Label
@export var player_stats: GridContainer
@export var party_inventory: GridContainer

@export var player_health_bar: ProgressBar
@export var player_exp_bar: ProgressBar
@export var enemy_health_bar: ProgressBar

var stat_containers = [
	world_stats,
	player_stats,
	enemy_stats
]

var labels = []
var label_entry = {
	"obj": null,
	"key": "",
	"label": null,
}

var string_n := 8


func _get_substring(string: String, n: int) -> String:
	var substring = ""
	substring = string if string.length() <= string_n else string.substr(0, n) + "..."
	return substring

func _update_labels(curr_labels: Array):
	# delete labels with invalid objects
	var invalid_entries = curr_labels.filter(func(l): return !is_instance_valid(l.obj))
	for i in range(invalid_entries.size()):
		# queue the label for deletion
		if is_instance_valid(invalid_entries[i].label):
			if !invalid_entries[i].label.is_queued_for_deletion():
				invalid_entries[i].label.queue_free()
		# remove the entry from current labels
		curr_labels.erase(invalid_entries[i])

	# player progress bars updated directly
	var p = self.world.data.controller.player_controller.player
	if is_instance_valid(p):
		# update class title
		self.player_class.text = p.get_class_string()
		# update progress bars
		self.player_health_bar.value = p.data.stats.health
		self.player_health_bar.max_value = p.data.stats.max_health
		self.player_exp_bar.value = p.data.stats.exp
		self.player_exp_bar.max_value = p.data.stats.exp_cap
	
	## TODO: make this account for multiple enemies
	var enemies = self.world.data.controller.enemy_controller.enemies
	if !enemies.is_empty():
		var e = enemies[0]
		if is_instance_valid(e):
			# update progress bars
			self.enemy_health_bar.value = e.data.stats.health
			self.enemy_health_bar.max_value = e.data.stats.max_health
			self.enemy_health_bar.show()
	else:
		self.enemy_health_bar.hide()
	
	# traverse labels
	for l in curr_labels:
		# if object is valid and not queued for deletion,
		if is_instance_valid(l.obj) && !l.obj.is_queued_for_deletion():
			var keys = l.key.split(".", false)
			var n_keys = 0
			var data_string = ""
			if keys.size() > 1:
				n_keys += keys.size()
				if n_keys == 2:
					data_string = _get_substring(str(l.obj.data[keys[0]][keys[1]]), self.string_n)
					l.label.text = data_string
				elif n_keys == 3:
					if l.obj.data[keys[0]][keys[1]][keys[2]] is Weapon:
						var weapon_class = l.obj.data[keys[0]][keys[1]][keys[2]].get_weapon_class_string()
						data_string = _get_substring(str(weapon_class), self.string_n)
					else:
						data_string = _get_substring(str(l.obj.data[keys[0]][keys[1]][keys[2]]), self.string_n)
					l.label.text = data_string
			else:
				if l.obj is Controller:
					data_string = _get_substring(str(l.obj[l.key]), self.string_n)
					l.label.text = data_string
				else:
					data_string = _get_substring(str(l.obj.data[l.key]), self.string_n)
					l.label.text = data_string
	
	# update labels
	self.labels = curr_labels

## returns stringified obj data given the passed obj and entry key string
func _parse_label_entry(obj: Variant, entry_key: String) -> String:
	# check if nested key
	var keys = entry_key.split(".", false)
	var n_keys = 0
	if keys.size() > 0:
		n_keys += keys.size()
	
	var data_string = ""
	if n_keys == 2:
		data_string = str(obj.data[keys[0]][keys[1]])
	elif n_keys == 3:
		data_string = str(obj.data[keys[0]][keys[1]][keys[2]])
	else:
		data_string = str(obj.data[entry_key])
	return data_string

func _make_data_label(
	obj: Variant, key: String, container: String, entry_key: String = key,
):
	var new_name_label = Label.new()
	new_name_label.label_settings = self.stat_label_settings
	new_name_label.name = key
	new_name_label.text = entry_key
	new_name_label.clip_text = true
	new_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	new_name_label.custom_minimum_size = Vector2(140, 0)

	var new_data_label = Label.new()
	new_data_label.label_settings = self.stat_label_settings
	new_data_label.name = key + "_data"
	var data_string = null
	if obj is Controller:
		data_string = _get_substring(str(obj[key]), string_n)
	else:
		data_string = _parse_label_entry(obj, entry_key)
	
	new_data_label.text = data_string
	
	self [container].add_child(new_name_label)
	self [container].add_child(new_data_label)

	var new_label_entry = label_entry.duplicate()
	new_label_entry.obj = obj
	new_label_entry.key = entry_key
	new_label_entry.label = new_data_label

	self.labels.append(new_label_entry)

## traverses passed object data up to 3 layers deep using recursion,
## adds them to the passed stat_container,
## and processes ui controller label entries for updating labels
func _make_data_labels(obj: Variant, container: String):
	var world_filter = {
		0: ["uid", "terrain"],
		1: ["map_count", "resources", "encounters"],
		2: ["count"]
	}
	var player_filter = {
		0: ["stats", "skills", "resources", "inventory"]
	}
	var enemy_filter = {
		0: ["stats", "inventory"]
	}
	for k in obj.data:
		if (
			obj is World && k in world_filter[0] ||
			obj is Player && k in player_filter[0] ||
			obj is Enemy && k in enemy_filter[0]
		):
			if obj.data[k] is Dictionary:
				for k_n in obj.data[k]:
					if (
						obj is World && k_n in world_filter[1] ||
						obj is Player ||
						obj is Enemy
					):
						if obj.data[k][k_n] is Dictionary:
							for k_n_n in obj.data[k][k_n]:
								if (
									obj is World && k_n_n in world_filter[2] ||
									obj is Player ||
									obj is Enemy
								):
									var entry_key = ".".join([k, k_n, k_n_n])
									_make_data_label(obj, k_n_n, container, entry_key)
							
						else:
							var entry_key = ".".join([k, k_n])
							_make_data_label(obj, k_n, container, entry_key)

			else:
				_make_data_label(obj, k, container)

func _check_obj_labels(obj: Variant, curr_labels: Array):
	if is_instance_valid(obj):
		if !obj.is_queued_for_deletion():
			var found = curr_labels.filter(func(l): return l.obj == obj)
			if found.size() == 0:
				return false
			else:
				return found

func _init_enemy_stats(enemies: Array, curr_labels: Array):
	if !enemies.is_empty():
		# make stats
		## TODO: make this dynamic for arrays
		var found = _check_obj_labels(enemies[0], curr_labels)
		if !found:
			_make_data_labels(enemies[0], "enemy_stats")
			self.enemy_stats.show()
	else:
		# if enemies array empty, delete lingering name labels
		var lingering = self.enemy_stats.get_children()
		for l in lingering:
			if is_instance_valid(l):
				if !l.is_queued_for_deletion():
					l.queue_free()

		self.enemy_stats.hide()

func _init_player_stats():
	var p = self.world.data.controller.player_controller.player
	_make_data_labels(p, "player_stats")

func _init_world_stats():
	# make world labels
	var w = self.world
	_make_data_labels(w, "world_stats")
	# make time data labels
	var t = self.world.data.controller.time_controller
	_make_data_label(t, "frame_rate", "world_stats")
	_make_data_label(t, "cycles", "world_stats")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# get file logger
	self.FileLogger = $"/root/FileLogger"

	# define label settings
	var new_stat_label_settings = LabelSettings.new()
	new_stat_label_settings.font = preload("res://src/assets/JetBrainsMono-Medium.ttf")
	new_stat_label_settings.font_size = 13
	self.stat_label_settings = new_stat_label_settings # define label settings

	# init stat panels
	_init_player_stats()
	_init_world_stats()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_init_enemy_stats(
		self.world.data.controller.enemy_controller.enemies,
		self.labels)
	_update_labels(self.labels)