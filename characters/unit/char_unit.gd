extends Node3D

const _STEP_INTERVAL: int = 400
const _STEP_MINSPEED: float = 5.0
const _STEP_MINSPEED_SQ: float = _STEP_MINSPEED * _STEP_MINSPEED

var _team: String = "none"
@export var team: String = "none":
	get:
		return _team
	set(v):
		_team = v
		_assign_team()


var pawn: GsomPawn = null:
	get:
		return _pawn

var _prev_step_time: int = 0

@onready var _pawn: GsomPawn = $GsomPawn
@onready var _steps: Node = $Steps

static var _units: Array[GsomPawn] = []


static func get_units() -> Array[GsomPawn]:
	return _units


func _ready() -> void:
	_units.append(_pawn)
	_assign_team()


func _exit_tree() -> void:
	_units.erase(_pawn)


func _process(_dt: float) -> void:
	_step()


func _assign_team() -> void:
	if _pawn:
		_pawn.set_trait("team", _team)


func _step() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - _prev_step_time < _STEP_INTERVAL:
		return
	
	var is_ground: bool = pawn.get_state("on_ground", false)
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
