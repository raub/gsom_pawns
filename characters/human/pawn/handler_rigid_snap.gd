@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

var has_position: bool = false
var prev_position: Vector3 = Vector3()

func _do_physics(pawn: GsomPawn, _dt: float) -> void:
	if !pawn.has_env("snap"):
		has_position = false
		return
	
	var snap: Dictionary = pawn.get_env("snap")
	var target: Node = snap.target
	if target is not Node3D:
		return
	
	var target3d: Node3D = target
	if !has_position:
		has_position = true
		prev_position = target3d.global_position
		return
	
	var delta_pos: Vector3 = target3d.global_position - prev_position
	prev_position = target3d.global_position
	
	var is_ground: bool = pawn.get_state("on_ground", false)
	if !is_ground:
		return
	
	pawn.body.global_position += delta_pos
