extends GsomPawnHull

const PawnWalk = preload("./pawn_rigid_walk.gd")

var _walk := PawnWalk.new();


@onready var _mesh: MeshInstance3D = $Mesh
@onready var _cast: ShapeCast3D = $Cast
@onready var _cast_up: ShapeCast3D = $CastUp
@onready var _ray: RayCast3D = $Ray


func _ready() -> void:
	_walk._mesh = _mesh
	_walk._cast = _cast
	_walk._cast_up = _cast_up
	_walk._ray = _ray
	
	_cast_up.enabled = false
	
	var rigid := get_parent() as RigidBody3D
	if rigid:
		_cast.add_exception(rigid)
		_ray.add_exception(rigid)
	
	_exit_hull();
	_walk._assign_is_debug_mesh();


func _check_enter() -> bool:
	return true


func _check_exit() -> bool:
	return true


func _enter_hull() -> void:
	visible = true
	disabled = false
	_cast.enabled = true
	_ray.enabled = true


func _exit_hull() -> void:
	visible = false
	disabled = true
	_cast.enabled = false
	_ray.enabled = false


func _get_head_y() -> float:
	return 1.2


func _do_process(dt: float) -> void:
	_walk._do_process(dt)


func _do_integrate(pawn: GsomPawnRigid, state: PhysicsDirectBodyState3D) -> void:
	_walk._do_integrate(pawn, state)


func _do_physics(pawn: GsomPawnRigid, dt: float) -> void:
	_walk._do_physics(pawn, dt)
