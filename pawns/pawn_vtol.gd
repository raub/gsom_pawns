extends RigidBody3D


var _pawn: GsomPawn = null


func _ready() -> void:
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_pawn.head_y_target = 0.5


func _process(dt: float) -> void:
	_pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	_pawn.do_physics(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_pawn.do_integrate(state)
