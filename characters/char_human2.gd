extends Node3D

const _STEP_INTERVAL: int = 400


var pawn: GsomPawn = null:
	get:
		return _pawn


var _prev_step_time: int = 0

@onready var _pawn: GsomPawn = $GsomPawn
@onready var _steps: Node = $Steps


func _ready() -> void:
	pass


func _process(_dt: float) -> void:
	_step()


func _step() -> void:
	var time_now = Time.get_ticks_msec()
	
	if time_now - _prev_step_time < _STEP_INTERVAL:
		return
	
	var is_ground: bool = pawn.get_env("on_ground", false)
	if !is_ground or _pawn.speed < 5.0:
		return
	
	_prev_step_time = time_now
	
	var count: int = _steps.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := _steps.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()
