extends Node

# refs
var ui_controller: Control

# components
const LOG_FILE_PATH = "res://world_log.txt"

## initializes the FileLogger
func _ready() -> void:
    var file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
    if file:
        file.store_string("[%s] --- Logger Initialized ---\n" % _get_timestamp())
        file.close()

## logs the passed message to log file ./world_log.txt
## according to timestamp, caller, and alert level
func log_message(
    caller: Variant,
    message: String,
    level: String = "INFO"
) -> void:
    var timestamp = _get_timestamp()
    # determine message level
    var new_level = ""
    var s_caller: String = caller.name.replace("Controller", "")
    new_level = s_caller
    level = new_level

    # format message
    var formatted_message = "[%s] [%s] %s\n" % [timestamp, level.to_upper(), message]
    print(formatted_message.strip_edges())

    # check file validity,
    var file: FileAccess
    if not FileAccess.file_exists(LOG_FILE_PATH):
        file = FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
    else:
        file = FileAccess.open(LOG_FILE_PATH, FileAccess.READ_WRITE)
        if file:
            file.seek_end() # move cursor to end of file
    
    # if file valid, write
    if file:
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