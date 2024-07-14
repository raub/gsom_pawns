extends CharacterBody3D


var _is_debug_mesh := true
## Show the debug mesh (default to true so you can see the pawn when added)
@export var is_debug_mesh := true:
	get:
		return _is_debug_mesh
	set(v):
		_is_debug_mesh = v
		_assign_is_debug_mesh()


var _max_speed: float = 3.0
## Maximum movement speed for this pawn
@export var max_speed: float = 3.0:
	get:
		return _max_speed
	set(v):
		_max_speed = v
		_assign_max_speed()


var _pending_toss_vel := Vector3.ZERO
var _has_pending_tp := false
var _pending_tp_pos := Vector3.ZERO
var _pawn: GsomPawn = null


@onready var _mesh: MeshInstance3D = $Shape/Mesh
@onready var _navigator: NavigationAgent3D = $NavigationAgent3D
@onready var _debug_next: MeshInstance3D = $__DebugNext
@onready var _debug_end: MeshInstance3D = $__DebugEnd


func _ready() -> void:
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_assign_max_speed()
	_assign_is_debug_mesh()
	
	_pawn.triggered.connect(_handle_triggers)
	_navigator.velocity_computed.connect(_update_velocity)


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
		global_position = _pending_tp_pos
		_has_pending_tp = false
		_pending_tp_pos = Vector3.ZERO
		_pawn.reset_actions()
		_pawn.reset_envs()
		_pawn.moved.emit(global_position)
		return
	
	_debug_next.visible = _is_debug_mesh and _pawn.has_action("move")
	_debug_end.visible = _is_debug_mesh and _pawn.has_action("move")
	
	if _pawn.has_action("move"):
		var move_target: Vector3 = _pawn.get_action("move")
		_debug_end.position = move_target
		_navigator.set_target_position(move_target)
	
	if !_navigator.is_navigation_finished():
		var next_pos: Vector3 = _navigator.get_next_path_position()
		_debug_next.position = next_pos
		var new_velocity: Vector3 = global_position.direction_to(next_pos) * max_speed
		_navigator.velocity = new_velocity # avoidance
		#velocity = new_velocity # for no avoidance
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()
	
	_pawn.do_physics(dt)


func _update_velocity(safe_velocity: Vector3) -> void:
	if !_navigator.is_navigation_finished():
		velocity = safe_velocity


func _assign_is_debug_mesh() -> void:
	if _mesh:
		_mesh.visible = _is_debug_mesh
		_debug_next.visible = _is_debug_mesh and _pawn.has_action("move")
		_debug_end.visible = _is_debug_mesh and _pawn.has_action("move")


func _assign_max_speed() -> void:
	if _navigator:
		_navigator.max_speed = _max_speed
