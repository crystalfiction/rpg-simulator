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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass