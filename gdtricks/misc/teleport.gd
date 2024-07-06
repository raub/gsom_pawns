extends Node

@export var tag: String = ""
@export var dest: String = ""


func _ready() -> void:
	add_to_group("Teleport")
	var parent: Node = get_parent()
	if parent is Area3D:
		attachArea(parent as Area3D)


func attachArea(area: Area3D) -> void:
	if !area.body_entered.is_connected(_tryToTeleport):
		area.body_entered.connect(_tryToTeleport)


func detachArea(area: Area3D) -> void:
	if area.body_entered.is_connected(_tryToTeleport):
		area.body_entered.disconnect(_tryToTeleport)


func _try_play_sound() -> void:
	for child: Node in get_children():
		if child.has_method("play"):
			child.call("play")
			break


func _tryToTeleport(body: Node3D) -> void:
	if dest.is_empty():
		push_warning("Teleport - no 'dest'.")
		return
	
	var _pawn := body.get_parent() as GsomPawn;
	
	if !_pawn:
		return
	
	var teleports: Array = body.get_tree().get_nodes_in_group("Teleport").filter(
		func (node: Node) -> bool:
			return node.tag == dest
	)
	if teleports.is_empty():
		push_warning("Teleport - '%s' not found." % dest)
		return
	
	var dest_teleport: Node = teleports.front()
	var parent_3d := dest_teleport.get_parent() as Node3D
	
	if !parent_3d:
		push_warning("Teleport - destination is not in Node3D.")
		return
	
	_pawn.triggered.emit("teleport", parent_3d.global_position)
	
	_try_play_sound()


static func getAvailabeTags(body: Node3D) -> PackedStringArray:
	var result: PackedStringArray = []
	
	body.get_tree().get_nodes_in_group("Teleport").all(
		func (node: Node) -> bool:
			if !node.tag.is_empty():
				result.push_back(node.tag)
			return true
	)
	
	return result
