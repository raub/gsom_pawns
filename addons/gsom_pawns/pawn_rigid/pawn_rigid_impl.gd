extends RigidBody3D


func _ready() -> void:
	pass


func _process(dt: float) -> void:
	get_parent()._do_process(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	get_parent()._do_integrate(state)


func _physics_process(dt: float) -> void:
	get_parent()._do_physics(dt)
