extends Node3D
class_name CharSpec


var pawn: GsomPawn = null:
	get:
		return _pawn


@onready var _pawn: GsomPawn = $GsomPawn


func _ready() -> void:
	pass
