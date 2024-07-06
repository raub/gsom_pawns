extends RigidBody3D

const _HEAD_WALK: float = 1.55
const _HEAD_DUCK: float = 1.2


var _is_debug_mesh := true
## Show the debug mesh (default to true so you can see the pawn when added)
@export var is_debug_mesh := true:
	get:
		return _is_debug_mesh
	set(v):
		_is_debug_mesh = v
		_assign_is_debug_mesh()

## Limits what slopes are still considered ground.
## Higher values will cause even small slopes to be considered steep.
@export_range(0.2, 0.9) var slope_normal_y: float = 0.75


var _vell := Vector3.ZERO
var _pending_toss_vel := Vector3.ZERO
var _has_pending_tp := false
var _pending_tp_pos := Vector3.ZERO

var _pawn: GsomPawn = null
var _is_ground := false

var _normal := Vector3.UP
## Get the current body-to-ground normal
var normal: Vector3 = _normal:
	get:
		return _normal


@onready var _shape_walk: CollisionShape3D = $ShapeWalk
@onready var _shape_duck: CollisionShape3D = $ShapeDuck
@onready var _mesh_walk: MeshInstance3D = $ShapeWalk/Mesh
@onready var _mesh_duck: MeshInstance3D = $ShapeDuck/Mesh
@onready var _cast: ShapeCast3D = $Cast
@onready var _cast_up: ShapeCast3D = $CastUp
@onready var _ray: RayCast3D = $Ray
@onready var _marker_duck: Marker3D = $MarkerDuck
@onready var _marker_walk: Marker3D = $MarkerWalk


func _ready() -> void:
	_cast_up.add_exception(self)
	_cast.add_exception(self)
	_ray.add_exception(self)
	
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_pawn.triggered.connect(_handle_triggers)
	
	_unduck()
	
	_assign_is_debug_mesh()


func _handle_triggers(trigger_name: String, value: Variant) -> void:
	if trigger_name == "teleport":
		_has_pending_tp = true
		_pending_tp_pos = value # Vector3
	elif trigger_name == "toss":
		_pending_toss_vel += value # Vector3


func _duck() -> void:
	if _pawn.get_env("crouching", false):
		return
	
	_pawn.set_env("crouching", true)
	
	_shape_walk.disabled = true
	_shape_duck.disabled = false
	
	_mesh_walk.visible = false
	_mesh_duck.visible = is_debug_mesh
	
	_cast_up.enabled = true
	
	_cast.position.y = _marker_duck.position.y
	_ray.position.y = _marker_duck.position.y
	
	_pawn.head_y_target = _HEAD_DUCK


func _unduck() -> void:
	if _cast_up.is_colliding() or !_pawn.get_env("crouching", true):
		return
	
	_pawn.set_env("crouching", false)
	
	# HACK: don't let the full shape pierce into floor
	if _is_ground:
		global_position.y += _shape_duck.position.y - 0.45
	
	_shape_walk.disabled = false
	_shape_duck.disabled = true
	
	_mesh_walk.visible = is_debug_mesh
	_mesh_duck.visible = false
	
	_cast_up.enabled = false
	
	_cast.position.y = _marker_walk.position.y
	_ray.position.y = _marker_walk.position.y
	
	_pawn.head_y_target = _HEAD_WALK


# Detect the isGround state from collision results from shape and ray casts
# If was in air and hit ground - emits `pawn.hit_ground`
func _update_ground_state() -> void:
	var result: Array = _cast.collision_result
	var wasGround: bool = _is_ground
	_is_ground = false
	_normal = Vector3.UP
	
	if !result.size():
		_pawn.set_env("normal", _normal)
		return
	
	var max_y := Vector3.ZERO
	for item: Dictionary in result:
		if item.normal.y > max_y.y:
			max_y = item.normal
	
	if max_y.y < slope_normal_y:
		_pawn.set_env("normal", _normal)
		return
	
	_normal = max_y
	_is_ground = true
	
	if !wasGround:
		_pawn.triggered.emit("hit_ground", _vell.y - linear_velocity.y)
	
	if _ray.is_colliding():
		_normal = _ray.get_collision_normal()
	
	_pawn.set_env("normal", _normal)


func _process(dt) -> void:
	_pawn.do_process(dt)


func _physics_process(dt) -> void:
	if _has_pending_tp:
		linear_velocity = Vector3.ZERO
		global_position = _pending_tp_pos
		_has_pending_tp = false
		_pending_tp_pos = Vector3.ZERO
		_pawn.reset_envs()
		_pawn.moved.emit(global_position)
		return
	
	_update_ground_state()
	
	_pawn.set_env("up_blocked", _cast_up.is_colliding())
	_pawn.set_env("on_ground", _is_ground)
	
	if _pawn.get_action("duck", false):
		_duck()
	else:
		_unduck()
	
	_pawn.do_physics(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_pawn.do_integrate(state)


func _assign_is_debug_mesh() -> void:
	if !_mesh_walk:
		return
	
	_mesh_walk.visible = _is_debug_mesh and _shape_duck.disabled
	_mesh_duck.visible = _is_debug_mesh and _shape_walk.disabled
