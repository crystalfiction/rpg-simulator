extends Control

# references
var world: World

# components
@export var player_data_container: GridContainer
@export var player_exp_bar: ProgressBar
@export var loading_scene: CenterContainer
var label_settings: LabelSettings
var labels = []


func _update_player_labels():
	# label entry: [ entity, key, label ]
	for l in self.labels:
		var entity = l[0]
		if !is_instance_valid(entity):
			return
			
		var key = l[1]
		var label = l[2]
		label.text = str(entity.data.stats[key])

		if key == "exp":
			# update exp bar
			self.player_exp_bar.value = entity.data.stats[key]
		elif key == "exp_cap":
			self.player_exp_bar.max_value = entity.data.stats[key]


func _init_player_labels():
	var player = self.world.data.player
	if "stats" in player.data:
		for s in player.data.stats:
			var data_key = s
			var new_key_label = Label.new()
			new_key_label.text = s

			var data = player.data.stats[s]
			var new_data_label = Label.new()
			new_data_label.text = str(data)

			var new_label_set = [player, data_key, new_data_label]
			self.labels.append(new_label_set)

			self.player_data_container.add_child(new_key_label)
			self.player_data_container.add_child(new_data_label)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_player_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update_player_labels()