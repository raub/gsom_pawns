extends Node3D

const _MODULATE_FRIENDLY := Color("#1eff1b")
const _MODULATE_ENEMY := Color("#ff1e1b")


var _is_friendly: bool = false
@export var is_friendly: bool = false:
	get:
		return _is_friendly
	set(v):
		if _is_friendly == v:
			return
		_is_friendly = v
		_assign_is_friendly()

@onready var _bar: Sprite3D = $Bar


func _ready() -> void:
	_assign_is_friendly()


func _assign_is_friendly() -> void:
	if !_bar:
		return
	
	_bar.modulate = _MODULATE_FRIENDLY if _is_friendly else _MODULATE_ENEMY
