extends RigidBody3D


var _parent: GsomPawnRigid = null


func _ready() -> void:
	_parent = get_parent() as GsomPawnRigid
	if !_parent:
		push_error("Parent must be a GsomPawnRigid.")



func teleport(pos: Vector3) -> void:
	_parent.teleport(pos)


func toss(velocity: Vector3) -> void:
	_parent.toss(velocity)


func _process(dt: float) -> void:
	_parent._do_process(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_parent._do_integrate(state)


func _physics_process(dt: float) -> void:
	_parent._do_physics(dt)
