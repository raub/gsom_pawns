extends Node3D

const _STEP_GROUND_INTERVAL: int = 400
const _STEP_GROUND_MINSPEED: float = 5.0
const _STEP_GROUND_MINSPEED_SQ: float = _STEP_GROUND_MINSPEED * _STEP_GROUND_MINSPEED

const _STEP_LADDER_INTERVAL: int = 600
const _STEP_LADDER_MINSPEED_SQ: float = 1.0

const _STEP_SWIM_INTERVAL: int = 2000


var pawn: GsomPawn = null:
	get:
		return _pawn

var _prev_step_ground_time: int = 0
var _prev_step_ladder_time: int = 0
var _prev_step_swim_time: int = 0

@onready var _pawn: GsomPawn = $GsomPawn
@onready var _steps_concrete: Node = $StepsConcrete
@onready var _steps_metal: Node = $StepsMetal
@onready var _steps_ladder: Node = $StepsLadder
@onready var _steps_swim: Node = $StepsSwim
@onready var _steps_wet: Node = $StepsWet
@onready var _helmet: Node = $helmet


func _ready() -> void:
	_helmet.set_fly(false)
	_helmet.set_swim(false)
	_helmet.set_direction(Vector2.ZERO)
	_helmet.set_crouch(false)


func _process(_dt: float) -> void:
	_produce_step_sound()
	
	var view_basis: Basis = _pawn.get_action("basis", Basis.IDENTITY)
	var forward: Vector3 = Vector3.UP.cross(view_basis.x)
	var left: Vector3 = Vector3.UP.cross(-view_basis.z)
	global_transform.basis = Basis.looking_at(forward, Vector3.UP, true)
	
	var vel: Vector3 = _pawn.linear_velocity
	var speed: float = vel.length()
	var dir := Vector2(vel.x, vel.z).normalized()
	var dot_forward: float = Vector2(forward.x, forward.z).dot(dir)
	var dot_left: float = Vector2(left.x, left.z).dot(dir)
	
	var is_duck: bool = _pawn.get_state("duck", false)
	_helmet.position.y = 0.45 if is_duck else 0.0
	
	var anim_xz := Vector2(dot_forward, dot_left) * speed * 0.1
	_helmet.set_direction(Vector2(minf(1.0, anim_xz.x), minf(1.0, anim_xz.y)))
	_helmet.set_crouch(is_duck)
	
	var is_water: bool = pawn.has_env("water")
	_helmet.set_swim(is_water)
	if is_water:
		_helmet.set_fly(false)
		return
	
	var is_jump: bool = pawn.get_action("jump", false)
	var is_ground: bool = pawn.get_state("on_ground", false)
	
	_helmet.set_fly(!is_ground)
	
	if is_ground and is_jump:
		_helmet.jump()



func _produce_step_sound() -> void:
	var is_water: bool = pawn.has_env("water")
	if is_water:
		_try_step_swim()
		return
	
	var is_ground: bool = pawn.get_state("on_ground", false)
	if is_ground:
		_try_step_ground()
		return
	
	var is_ladder: bool = pawn.has_env("ladder")
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
	
	var host_node: Node = _steps_concrete
	
	var surface: Dictionary = pawn.get_env("surface", {})
	if surface.has("material"):
		if surface.material == "metal":
			host_node = _steps_metal
		if surface.material == "water":
			host_node = _steps_wet
	
	var count: int = host_node.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := host_node.get_child(rand_idx) as AudioStreamPlayer3D
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


func _try_step_swim() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - _prev_step_swim_time < _STEP_SWIM_INTERVAL:
		return
	
	_prev_step_swim_time = time_now
	
	var count: int = _steps_swim.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := _steps_swim.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()
