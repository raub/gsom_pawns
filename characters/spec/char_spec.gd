extends Node3D


var pawn: GsomPawn = null:
	get:
		return _pawn


@onready var _pawn: GsomPawn = $GsomPawn


func _ready() -> void:
	pass
