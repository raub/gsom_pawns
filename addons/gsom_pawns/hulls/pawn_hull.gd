extends CollisionShape3D
class_name GsomPawnHull


func _check_enter() -> bool:
	return true


func _check_exit() -> bool:
	return true


func _enter_hull() -> void:
	pass


func _exit_hull() -> void:
	pass


func _get_head_y() -> float:
	return 0.0


func _do_process(_dt: float) -> void:
	pass


func _do_integrate(_pawn: GsomPawnRigid, _state: PhysicsDirectBodyState3D) -> void:
	pass


func _do_physics(_pawn: GsomPawnRigid, _delta: float) -> void:
	pass
