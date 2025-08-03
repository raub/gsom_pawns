extends Node3D
class_name PortalDoor

@onready var _teleport: Teleport = $Area/Teleport


var _dest: String = ""
@export var dest: String = "":
	get:
		return _dest
	set(v):
		_dest = v
		_assignDest()


func _ready() -> void:
	_assignDest()


func _assignDest() -> void:
	if _teleport:
		_teleport.dest = _dest
