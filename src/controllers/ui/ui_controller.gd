extends Control

# references
var world: World

# components
@export var world_data_container: GridContainer
@export var player_data_container: GridContainer
@export var player_exp_bar: ProgressBar

@export var loading_scene: CenterContainer

var label_settings: LabelSettings
var labels = []


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
				label.text = str(entity.data.stats[key])
			else:
				label.text = str(snapped(entity.data.stats[key], 0))

		if entity is World:
			if key == "map_count":
				label.text = str(entity.data.terrain[key])


func _init_player_labels():
	var player = self.world.data.player
	if "stats" in player.data:
		for s in player.data.stats:
			var data_key = s
			var new_key_label = Label.new()
			new_key_label.name = s
			new_key_label.text = s

			var data = player.data.stats[s]
			var new_data_label = Label.new()
			new_data_label.name = s + "_data"
			new_data_label.text = str(snapped(data, 0))

			var new_label_set = [player, data_key, new_data_label]
			self.labels.append(new_label_set)

			self.player_data_container.add_child(new_key_label)
			self.player_data_container.add_child(new_data_label)


func _init_world_labels():
	var map_count = self.world.data.terrain.map_count
	var new_key_label = Label.new()
	new_key_label.text = "map_count"
	new_key_label.name = "map_count"
	var new_data_label = Label.new()
	new_data_label.name = new_key_label.name + "_data"
	new_data_label.text = str(map_count)
	self.labels.append([ self.world, new_key_label.name, new_data_label])
	self.world_data_container.add_child(new_key_label)
	self.world_data_container.add_child(new_data_label)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_world_labels()
	_init_player_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_labels()