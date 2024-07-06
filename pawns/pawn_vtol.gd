extends RigidBody3D


var _is_debug_mesh := true
## Show the debug mesh (default to true so you can see the pawn when added)
@export var is_debug_mesh := true:
	get:
		return _is_debug_mesh
	set(v):
		_is_debug_mesh = v
		_assign_is_debug_mesh()


var _pending_toss_vel := Vector3.ZERO
var _has_pending_tp := false
var _pending_tp_pos := Vector3.ZERO

var _pawn: GsomPawn = null


@onready var _mesh: MeshInstance3D = $Shape/Mesh
@onready var _engine_1: MeshInstance3D = $Shape/Mesh/Engine1
@onready var _engine_2: MeshInstance3D = $Shape/Mesh/Engine2


func _ready() -> void:
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_pawn.triggered.connect(_handle_triggers)
	
	_pawn.head_y_target = 0.5


func _handle_triggers(trigger_name: String, value: Variant) -> void:
	if trigger_name == "teleport":
		_has_pending_tp = true
		_pending_tp_pos = value # Vector3
	elif trigger_name == "toss":
		_pending_toss_vel += value # Vector3


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
	
	_pawn.do_physics(dt)
	
	if _is_debug_mesh:
		if _pawn.get_action("sprint", false) or _pawn.get_action("forward", false):
			_engine_1.position = Vector3(0.25, 0.0, 0.5)
			_engine_2.position = Vector3(-0.25, 0.0, 0.5)
		else:
			_engine_1.position = Vector3(0.25, -0.25, 0.0)
			_engine_2.position = Vector3(-0.25, -0.25, 0.0)
	


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_pawn.do_integrate(state)


func _assign_is_debug_mesh() -> void:
	if _mesh:
		_mesh.visible = _is_debug_mesh
