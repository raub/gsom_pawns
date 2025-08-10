extends Node3D
class_name PawnSpec

var linear_velocity := Vector3.ZERO
var __pawn: GsomPawn = null


func _ready() -> void:
	__pawn = get_parent() as GsomPawn
	if !__pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	__pawn.head_y_target = 0.0


func _process(dt: float) -> void:
	__pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	if linear_velocity.length() > 0.01:
		global_position += linear_velocity * dt

	__pawn.do_physics(dt)
