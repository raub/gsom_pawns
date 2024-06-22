extends Node3D

const _STEP_INTERVAL: int = 400

## The body has finished the '_physics_process' logic. This is the right time
## to fetch the position.
signal moved(pos: Vector3, head_y: float)

var head_y: float = 0.0:
	get:
		return _gsom_pawn_rigid.head_y


## Get current speed from the latest recorded velocity value.
var speed: float = 0.0:
	get:
		return _gsom_pawn_rigid.speed


var hull: String = "Walk":
	get:
		return _gsom_pawn_rigid.hull
	set(v):
		_gsom_pawn_rigid.hull = v


var wish_axis: Vector3 = Vector3.ZERO:
	get:
		return _gsom_pawn_rigid.wish_axis
	set(v):
		_gsom_pawn_rigid.wish_axis = v


var head_basis: Basis = Basis.IDENTITY:
	get:
		return _gsom_pawn_rigid.head_basis
	set(v):
		_gsom_pawn_rigid.head_basis = v

var _prev_step_time: int = 0

@onready var _gsom_pawn_rigid: GsomPawnRigid = $GsomPawnRigid
@onready var _steps: Node = $Steps


func _process(_dt: float) -> void:
	_step()


func _ready() -> void:
	_gsom_pawn_rigid.moved.connect(
		func (pos: Vector3, y: float) -> void: moved.emit(pos, y),
	)


func _step() -> void:
	var time_now = Time.get_ticks_msec()
	
	if time_now - _prev_step_time < _STEP_INTERVAL:
		return
	
	if !_gsom_pawn_rigid.is_ground or _gsom_pawn_rigid.speed < 5.0:
		return
	
	_prev_step_time = time_now
	
	var count: int = _steps.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := _steps.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()


func teleport(pos: Vector3) -> void:
	_gsom_pawn_rigid.teleport(pos)
