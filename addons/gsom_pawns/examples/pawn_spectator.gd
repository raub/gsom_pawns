extends Node3D


var linear_velocity := Vector3.ZERO
var _pawn: GsomPawn = null


func _ready() -> void:
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_pawn.head_y_target = 0.0


func _process(dt: float) -> void:
	_pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	if linear_velocity.length() > 0.01:
		global_position += linear_velocity * dt

	_pawn.do_physics(dt)
