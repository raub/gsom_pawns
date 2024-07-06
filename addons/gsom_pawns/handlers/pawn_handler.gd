extends Node
class_name GsomPawnHandler


## Disabled handlers are skipped.
@export var disabled := false


## Reimplement this to update the body on [code]_process[/code].
func _do_process(_pawn: GsomPawn, _dt: float) -> void:
	pass


## Reimplement this to update the body on [code]_integrate_forces[/code].
func _do_integrate(_pawn: GsomPawn, _state: PhysicsDirectBodyState3D) -> void:
	pass


## Reimplement this to update the body on [code]_physics_process[/code].
func _do_physics(_pawn: GsomPawn, _delta: float) -> void:
	pass
