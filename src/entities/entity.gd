class_name Entity extends Node2D

# components
var Type: EntityType
enum EntityType {
    WORLD,
    TERRAIN,
    TILE,
    PLAYER,
    ENEMY,
    ITEM,
}

var data: Dictionary = {
    "uid": 0,
    "controller": "",
    # subclass data...
}