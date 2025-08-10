extends Node3D
class_name HealthBar

const __MODULATE_FRIENDLY := Color("#1eff1b")
const __MODULATE_ENEMY := Color("#ff1e1b")


var __is_friendly: bool = false
@export var is_friendly: bool = false:
	get:
		return __is_friendly
	set(v):
		if __is_friendly == v:
			return
		__is_friendly = v
		__assign_is_friendly()

@onready var __bar: Sprite3D = $Bar


func _ready() -> void:
	__assign_is_friendly()


func __assign_is_friendly() -> void:
	if !__bar:
		return
	
	__bar.modulate = __MODULATE_FRIENDLY if __is_friendly else __MODULATE_ENEMY
