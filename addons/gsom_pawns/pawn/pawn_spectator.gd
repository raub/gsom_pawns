extends Node3D


var _is_debug_mesh := true
## Show the debug mesh (default to true so you can see the pawn when added)
@export var is_debug_mesh := true:
	get:
		return _is_debug_mesh
	set(v):
		_is_debug_mesh = v
		_assign_is_debug_mesh()


var linear_velocity := Vector3.ZERO
var _pawn: GsomPawn = null


## Get the animated head/eye/camera position Y.
var head_y: float = 0.0:
	get:
		return 0.0


@onready var _mesh: MeshInstance3D = $Mesh


func _ready() -> void:
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return


func _process(dt) -> void:
	_pawn.do_process(dt)


func _physics_process(dt) -> void:
	_pawn.do_physics(dt)
	
	if linear_velocity.length() > 0.01:
		global_position += linear_velocity * dt


func _assign_is_debug_mesh() -> void:
	if _mesh:
		_mesh.visible = _is_debug_mesh