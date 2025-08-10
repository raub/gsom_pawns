extends Node3D

@onready var __teleport: Teleport = $Area/Teleport


var __dest: String = ""
@export var dest: String = "":
	get:
		return __dest
	set(v):
		__dest = v
		__assign_dest()


func _ready() -> void:
	__assign_dest()


func __assign_dest() -> void:
	if __teleport:
		__teleport.dest = __dest
