extends Control

# references
var world: World

# components
@export var world_data_container: GridContainer
@export var player_data_container: GridContainer
@export var player_exp_bar: ProgressBar
@export var player_health_bar: ProgressBar
@export var enemy_data_container: GridContainer
@export var enemy_health_bar: ProgressBar

@export var loading_scene: CenterContainer

var label_settings: LabelSettings
var labels = []


## updates existing labels in the labels array
## by directly reading its entity data
func _update_labels():
	# label entry: [ entity, key, label ]
	for l in self.labels:
		var entity = l[0]
		if !is_instance_valid(entity):
			return
		
		var key = l[1]
		var label = l[2]

		if entity is Player:
			if key == "exp":
				# update exp bar
				self.player_exp_bar.value = entity.data.stats[key]
				label.text = str(entity.data.stats[key])
			elif key == "exp_cap":
				self.player_exp_bar.max_value = entity.data.stats[key]
				label.text = str(snapped(entity.data.stats[key], 0))
			elif key == "health":
				self.player_health_bar.value = entity.data.stats[key]
				label.text = str(snapped(entity.data.stats[key], 0))
			elif key == "max_health":
				self.player_health_bar.max_value = entity.data.stats[key]
				label.text = str(snapped(entity.data.stats[key], 0))
			elif key == "hit_chance":
				label.text = str(entity.data.stats[key])
			else:
				label.text = str(snapped(entity.data.stats[key], 0))

		if entity is Enemy:
			if key == "health":
				self.enemy_health_bar.value = entity.data.stats[key]
				label.text = str(snapped(entity.data.stats[key], 0))
			elif key == "max_health":
				self.enemy_health_bar.max_value = entity.data.stats[key]
				label.text = str(snapped(entity.data.stats[key], 0))
			elif key == "hit_chance":
				label.text = str(entity.data.stats[key])
			elif key == "crit_chance":
				label.text = str(snapped(entity.data.stats[key], 0.01))
			else:
				label.text = str(snapped(entity.data.stats[key], 0))

		if entity is World:
			if key == "map_count":
				label.text = str(entity.data.terrain[key])

## initializes enemy labels in enemy panel
func _init_enemy_labels():
	var enemy_controller = self.world.data.controller.enemy_controller
	var enemies = enemy_controller.enemies
	# get array of current label objects
	var label_objs = []
	for l in self.labels:
		var obj = l[0]
		label_objs.append(obj)
	
	# if enemies array is valid,
	if !enemies.is_empty() && enemies != null:
		for e in enemies:
			# if enemy is valid,
			if is_instance_valid(e):
				# if enemy doesn't already have labels,
				if e not in label_objs:
					# if enemy dict valid,
					if "stats" in e.data:
						# for each enemy,
						for s in e.data.stats:
							if s == "level" || s == "health" || s == "attack":
								var data_key = s
								var new_key_label = Label.new()
								new_key_label.name = s
								new_key_label.text = s
								new_key_label.label_settings = self.label_settings

								var data = e.data.stats[s]
								var new_data_label = Label.new()
								new_data_label.name = s + "_data"
								new_data_label.text = str(snapped(data, 0))
								new_data_label.label_settings = self.label_settings

								var new_label_set = [e, data_key, new_data_label]
								self.labels.append(new_label_set)

								self.enemy_data_container.add_child(new_key_label)
								self.enemy_data_container.add_child(new_data_label)
			
			# if enemy is not valid,
			else:
				# delete enemy labels
				for l in self.labels:
					var obj = l[0]
					var label = l[2]
					# if object match and not already queued for deletion,
					if obj == e && !obj.is_queued_for_deletion():
						# delete label object
						label.queue_free()
						# delete entry from labels array
						self.labels.erase(l)
	
	# if enemies array empty,
	else:
		# delete invalid labels
		for l in self.labels:
			var obj = l[0]
			var label = l[2]
			# if object match and not already queued for deletion,
			if !is_instance_valid(obj):
				if is_instance_valid(label):
					# delete label object if still valid
					label.queue_free()
				# delete entry from labels array
				self.labels.erase(l)
			
			# delete lingering key labels
			var child_labels = self.enemy_data_container.get_children()
			for c in child_labels:
				if !c.is_queued_for_deletion():
					c.queue_free()

## initializes player data labels in the player data panel
func _init_player_labels():
	var player = self.world.data.player
	if "stats" in player.data:
		for s in player.data.stats:
			var data_key = s
			var new_key_label = Label.new()
			new_key_label.name = s
			new_key_label.text = s
			new_key_label.label_settings = self.label_settings

			var data = player.data.stats[s]
			var new_data_label = Label.new()
			new_data_label.name = s + "_data"
			new_data_label.text = str(snapped(data, 0))
			new_data_label.label_settings = self.label_settings

			var new_label_set = [player, data_key, new_data_label]
			self.labels.append(new_label_set)

			self.player_data_container.add_child(new_key_label)
			self.player_data_container.add_child(new_data_label)

## initializes world data labels in the world data panel
func _init_world_labels():
	var map_count = self.world.data.terrain.map_count
	var new_key_label = Label.new()
	new_key_label.text = "map_count"
	new_key_label.name = "map_count"
	new_key_label.label_settings = self.label_settings
	
	var new_data_label = Label.new()
	new_data_label.name = new_key_label.name + "_data"
	new_data_label.text = str(map_count)
	new_data_label.label_settings = self.label_settings
	
	self.labels.append([ self.world, new_key_label.name, new_data_label])
	self.world_data_container.add_child(new_key_label)
	self.world_data_container.add_child(new_data_label)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# define label settings
	var new_label_settings = LabelSettings.new()
	new_label_settings.font = load("res://src/assets/JetBrainsMono-Medium.ttf")
	new_label_settings.font_size = 13
	self.label_settings = new_label_settings

	# initialize labels
	_init_world_labels()
	_init_player_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_init_enemy_labels()
	_update_labels()