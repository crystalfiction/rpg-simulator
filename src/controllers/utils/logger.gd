extends Node

# refs
var ui_controller: Control

# components
const WORLD_LOG_PATH = "res://world_log.txt"
const GAME_LOG_PATH = "res://game_log.txt"
const Outputs = {
	"WORLD_LOG_PATH": WORLD_LOG_PATH,
	"GAME_LOG_PATH": GAME_LOG_PATH
}

## initializes the FileLogger
func _ready() -> void:
	var files = [
		WORLD_LOG_PATH,
		GAME_LOG_PATH,
	]
	for f in files:
		var mode = FileAccess.WRITE
		if f == GAME_LOG_PATH:
			if FileAccess.file_exists(f):
				var lines = _get_line_count(f)
				if lines > 1:
					mode = FileAccess.READ_WRITE
				
		var file = FileAccess.open(f, mode)
		if file:
			if f == GAME_LOG_PATH:
				file.seek_end()
			file.store_string("[%s] --- [%s] Initialized ---\n" % [_get_timestamp(), str(f)])
			file.close()

## logs the passed message to log file ./world_log.txt
## according to timestamp, caller, and alert level
func log_message(
	caller: Variant,
	message: String,
	level: String = "INFO",
	output: String = "WORLD_LOG_PATH"
) -> void:
	var timestamp = _get_timestamp()
	# determine message level
	var new_level: String = level
	var s_caller: String = caller.name.replace("Controller", "")
	level = new_level if new_level != "INFO" else s_caller

	# format message
	var formatted_message = "[%s] [%s] %s\n" % [timestamp, level.to_upper(), message]
	# print to debug console
	print(formatted_message.strip_edges())

	# check file validity,
	var file: FileAccess
	output = Outputs.get(output)
	if not FileAccess.file_exists(output):
		file = FileAccess.open(output, FileAccess.WRITE)
	else:
		file = FileAccess.open(output, FileAccess.READ_WRITE)
		if file:
			file.seek_end() # move cursor to end of file
	
	# if file valid, write
	if file:
		if output == GAME_LOG_PATH:
			file.store_string(message + "\n")
		else:
			file.store_string(formatted_message)
		file.flush() # force write immediately to prevent data loss
		file.close()

	
## gets the current datetime and formats it
## returns formatted datetime String
static func _get_timestamp() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

static func _get_line_count(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return 0
		
	var count = 0
	while not file.eof_reached():
		file.get_line()
		count += 1
		
	file.close()
	return count