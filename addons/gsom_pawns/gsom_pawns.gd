@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"GsomPawn", "Node", preload("./nodes/pawn.gd"), preload("./nodes/pawn.svg"),
	)
	add_custom_type(
		"GsomPawnEnv", "Node", preload("./nodes/pawn_env.gd"), preload("./nodes/pawn_env.svg"),
	)
	add_custom_type(
		"GsomPawnTrigger", "Node", preload("./nodes/pawn_trigger.gd"), preload("./nodes/pawn_trigger.svg"),
	)


func _exit_tree() -> void:
	remove_custom_type("GsomPawn")
	remove_custom_type("GsomPawnEnv")
	remove_custom_type("GsomPawnTrigger")
