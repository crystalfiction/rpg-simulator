extends Controller

# references
var enemy_scene = preload("res://src/entities/enemies/enemy.tscn")
var actions_controller_script = preload("res://src/controllers/enemy/actions_controller.gd")

var actions_controller: Controller

# components
var eid_ref = 0
var cycle_complete = false

var processing_array = []


# spawns n enemies on a given tiles encounter/resources
func spawn_enemies(tile: Tile, n: int):
	# init tile enemies data
	tile.data.enemies = {
		"ready": [],
		"done": []
	}
	for i in range(n):
		var e = _init_enemy_entity(tile)
		var map_count = self.world.terrain.map_count
		# initialize enemy data by map count
		e.data.level = map_count
		# append to tile enemies ready array
		tile.data.enemies.ready.append(e)
		# append enemy to processing array
		self.processing_array.append(e)


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

	self.e = new_enemy
	tile.add_child(new_enemy)
	
	# update uid ref
	world_controller.uid_ref += 1
	self.eid_ref += 1

	return self.e


# determines and processes player logic for a single time cycle
func process_cycle() -> bool:
	## General enemy logic
	# check if enemies processing
	var processing = self.processing_array.size() > 0
	if processing:
		for e in processing_array:
			# TODO: check enemy stats: health, etc
			if e.data.stats.health <= 0 && !e.is_queued_for_deletion():
				# TODO: remove if invalid/encounter complete
				e.queue_free()
				processing.erase(e)
	else:
		# if done processing, cycle complete
		self.cycle_complete = true

	# return cycle flag
	return self.cycle_complete


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
