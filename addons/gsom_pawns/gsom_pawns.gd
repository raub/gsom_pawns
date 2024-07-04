@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"GsomPawn", "Node", preload("./pawn/pawn.gd"), preload("./pawn/pawn.svg"),
	)
	add_custom_type(
		"GsomPawnHandlerWalk",
		"Node",
		preload("./handlers/pawn_handler_walk.gd"),
		preload("./handlers/pawn_handler.svg"),
	)
	add_custom_type(
		"GsomPawnHandlerSpec",
		"Node",
		preload("./handlers/pawn_handler_spec.gd"),
		preload("./handlers/pawn_handler.svg"),
	)


func _exit_tree() -> void:
	remove_custom_type("GsomPawn")
	remove_custom_type("GsomPawnHandlerWalk")
	remove_custom_type("GsomPawnHandlerSpec")
