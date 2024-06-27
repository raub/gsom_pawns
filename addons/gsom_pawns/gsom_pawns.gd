@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"GsomPawnRigid",
		"Node",
		preload("./pawn_rigid/pawn_rigid.gd"),
		preload("./pawn_rigid/pawn_rigid.svg"),
	)
	add_custom_type(
		"GsomPawn", "Node", preload("./pawn/pawn.gd"), preload("./pawn/pawn.svg"),
	)
	add_custom_type(
		"GsomPawnHandlerWalk",
		"Node",
		preload("./handlers/pawn_handler_walk.gd"),
		preload("./handlers/pawn_handler_walk.svg"),
	)


func _exit_tree() -> void:
	remove_custom_type("GsomPawnHuman")
	remove_custom_type("GsomPawn")
	remove_custom_type("GsomPawnHandlerWalk")
