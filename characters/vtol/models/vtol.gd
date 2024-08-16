extends Node3D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer

var _down_cache: bool = false

func set_down(value: bool) -> void:
	if _down_cache == value:
		return
	_down_cache = value
	_animation_player.play("engine_down" if value else "engine_up")
