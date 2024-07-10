extends Node3D

const _STEP_INTERVAL: int = 400
const _STEP_MINSPEED: float = 5.0
const _STEP_MINSPEED_SQ: float = _STEP_MINSPEED * _STEP_MINSPEED


var pawn: GsomPawn = null:
	get:
		return _pawn

var _prev_step_time: int = 0

@onready var _pawn: GsomPawn = $GsomPawn
@onready var _steps: Node = $Steps

static var _units: Array = []


static func get_units() -> Array:
	return _units


func _enter_tree() -> void:
	_units.append(self)


func _exit_tree() -> void:
	_units.erase(self)


func _process(_dt: float) -> void:
	_step()


func _step() -> void:
	var time_now = Time.get_ticks_msec()
	
	if time_now - _prev_step_time < _STEP_INTERVAL:
		return
	
	var is_ground: bool = pawn.get_env("on_ground", false)
	if !is_ground:
		return
	
	var velocity_xz: Vector2 = Vector2(_pawn.linear_velocity.x, _pawn.linear_velocity.z)
	if velocity_xz.length_squared() < _STEP_MINSPEED_SQ:
		return
	
	_prev_step_time = time_now
	
	var count: int = _steps.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := _steps.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()
