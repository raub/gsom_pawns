extends Node3D
class_name CharSpec


var pawn: GsomPawn = null:
	get:
		return __pawn


@onready var __pawn: GsomPawn = $GsomPawn


func _ready() -> void:
	pass
