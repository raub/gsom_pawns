extends Node3D

const _STEP_GROUND_INTERVAL: int = 400
const _STEP_GROUND_MINSPEED: float = 5.0
const _STEP_GROUND_MINSPEED_SQ: float = _STEP_GROUND_MINSPEED * _STEP_GROUND_MINSPEED

const _STEP_LADDER_INTERVAL: int = 600
const _STEP_LADDER_MINSPEED: float = 2.0
const _STEP_LADDER_MINSPEED_SQ: float = _STEP_GROUND_MINSPEED * _STEP_GROUND_MINSPEED


var pawn: GsomPawn = null:
	get:
		return _pawn

var _prev_step_ground_time: int = 0
var _prev_step_ladder_time: int = 0

@onready var _pawn: GsomPawn = $GsomPawn
@onready var _steps_concrete: Node = $StepsConcrete
@onready var _steps_ladder: Node = $StepsLadder


func _ready() -> void:
	pass


func _process(_dt: float) -> void:
	_produce_step_sound()


func _produce_step_sound() -> void:
	var is_ground: bool = pawn.get_state("on_ground", false)
	if is_ground:
		_try_step_ground()
		return
	
	var is_ladder: bool = pawn.get_state("on_ladder", false)
	if is_ladder:
		_try_step_ladder()
		return
	


func _try_step_ground() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - _prev_step_ground_time < _STEP_GROUND_INTERVAL:
		return
	
	var velocity_xz: Vector2 = Vector2(_pawn.linear_velocity.x, _pawn.linear_velocity.z)
	if velocity_xz.length_squared() < _STEP_GROUND_MINSPEED_SQ:
		return
	
	_prev_step_ground_time = time_now
	
	var count: int = _steps_concrete.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := _steps_concrete.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()


func _try_step_ladder() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - _prev_step_ladder_time < _STEP_LADDER_INTERVAL:
		return
	
	if _pawn.linear_velocity.length_squared() < _STEP_LADDER_MINSPEED_SQ:
		return
	
	_prev_step_ladder_time = time_now
	
	var count: int = _steps_ladder.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := _steps_ladder.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()
