@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

func _do_physics(pawn: GsomPawn, _dt: float) -> void:
	if !pawn.has_env("snap"):
		return
	
	var snap: Dictionary = pawn.get_env("snap")
	var get_delta_at: Callable = snap.get_delta_at
	
	var delta_pos: Vector3 = get_delta_at.call(pawn.body.global_position)
	pawn.body.global_position += delta_pos
