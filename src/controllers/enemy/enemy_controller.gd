extends Controller

# references
var enemy_scene = preload("res://src/entities/enemies/enemy.tscn")
var actions_controller_script = preload("res://src/controllers/enemy/actions_controller.gd")

var actions_controller: Controller

# components
var eid_ref = 0
var cycle_complete = false


# initializes enemy entity
func _init_enemy_entity(tile: Tile):
	var world_controller = self.world.data.controller
	var new_enemy = self.enemy_scene.instantiate()
	# metadata
	new_enemy.data.uid = world_controller.uid_ref
	new_enemy.data.eid = self.eid_ref
	new_enemy.name = "enemy_" + str(new_enemy.data.eid)
	new_enemy.data.world = self.world
	new_enemy.data.controller = self
	new_enemy.data.parent = tile

	var e = new_enemy
	tile.add_child(new_enemy)
	
	# update uid ref
	world_controller.uid_ref += 1
	self.eid_ref += 1

	return e


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# determines and processes enemy logic for a single time cycle
func _process_cycle() -> bool:
	# only evaluate if time cycling
	var time_controller = self.world.data.controller.time_controller
	if time_controller.cycling:
		pass
	return self.cycle_complete


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# process enemy cycle
	_process_cycle()
