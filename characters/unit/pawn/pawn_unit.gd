extends CharacterBody3D

const __MAX_SLOW_TICKS: int = 60
const __PATH_OFFSET_K: float = 0.05

var __is_debug_mesh := true
## Show the debug mesh (default to true so you can see the pawn when added)
@export var is_debug_mesh := true:
	get:
		return __is_debug_mesh
	set(v):
		__is_debug_mesh = v
		__assign_is_debug_mesh()


var __max_speed: float = 3.0
## Maximum movement speed for this pawn
@export var max_speed: float = 3.0:
	get:
		return __max_speed
	set(v):
		__max_speed = v
		__assign_max_speed()


var __slow_ticks: int = 0
var __pawn: GsomPawn = null


@onready var __mesh: MeshInstance3D = $Shape/Mesh
@onready var __navigator: NavigationAgent3D = $NavigationAgent3D
@onready var __debug_next: MeshInstance3D = $__DebugNext
@onready var __debug_end: MeshInstance3D = $__DebugEnd


func _ready() -> void:
	__pawn = get_parent() as GsomPawn
	if !__pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	__assign_max_speed()
	__assign_is_debug_mesh()
	
	__navigator.velocity_computed.connect(__update_velocity)


func _process(dt: float) -> void:
	__pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	__debug_next.visible = __is_debug_mesh and __pawn.has_action("move")
	__debug_end.visible = __is_debug_mesh and __pawn.has_action("move")
	
	if __pawn.has_action("move"):
		var move_target: Vector3 = __pawn.get_action("move")
		__debug_end.position = move_target
		__navigator.set_target_position(move_target)
	
	if !__navigator.is_navigation_finished():
		var next_pos: Vector3 = __navigator.get_next_path_position()
		__debug_next.position = next_pos
		var new_velocity: Vector3 = global_position.direction_to(next_pos) * max_speed
		__navigator.velocity = new_velocity # avoidance
		#velocity = new_velocity # for no avoidance
	else:
		velocity = Vector3.ZERO
	
	move_and_slide()
	
	__pawn.do_physics(dt)


func __update_velocity(safe_velocity: Vector3) -> void:
	if __navigator.is_navigation_finished():
		__slow_ticks = 0
		return
	
	velocity = safe_velocity
	
	if velocity.length_squared() < __max_speed * __max_speed * 0.5:
		__slow_ticks += 1
	else:
		__slow_ticks = maxi(0, __slow_ticks - 2)
	
	if __slow_ticks >= __MAX_SLOW_TICKS:
		var reduction: float = float(__MAX_SLOW_TICKS - __slow_ticks) * __PATH_OFFSET_K
		var move_target: Vector3 = __pawn.get_action("move")
		if __pawn.position.distance_squared_to(move_target) < reduction * reduction:
			__pawn.set_action("move", __pawn.position)


func __assign_is_debug_mesh() -> void:
	if __mesh:
		__mesh.visible = __is_debug_mesh
		__debug_next.visible = __is_debug_mesh and __pawn.has_action("move")
		__debug_end.visible = __is_debug_mesh and __pawn.has_action("move")


func __assign_max_speed() -> void:
	if __navigator:
		__navigator.max_speed = __max_speed
