@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"GsomPawnRigid", "Node", preload("./pawn_rigid/pawn_rigid.gd"), preload("./pawn_rigid/pawn_rigid.svg")
	)


func _exit_tree() -> void:
	remove_custom_type("GsomPawnHuman")
