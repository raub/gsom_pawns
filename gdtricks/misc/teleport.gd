extends Node

signal onSend(what, where)
signal onReceive(what)

signal onChangeTag(value)
signal onChangeDest(value)

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


func _tryPlaySound() -> void:
	for child: Node in get_children():
		if child.has_method("play"):
			child.call("play")
			break


func _tryToTeleport(body: Node3D) -> void:
	if dest.is_empty():
		push_warning("Teleport - no 'dest'.")
		return
	
	if !body.has_method("teleport"):
		return
	
	var teleports: Array = body.get_tree().get_nodes_in_group("Teleport").filter(
		func (node: Node) -> bool:
			return node.tag == dest
	)
	if teleports.is_empty():
		push_warning("Teleport - '%s' not found." % dest)
		return
	
	var destTeleport: Node = teleports.front()
	var parent: Node = destTeleport.get_parent()
	
	if !(parent is Node3D):
		push_warning("Teleport - destination is not in Node3D.")
		return
	
	var parent3d: Node3D = parent as Node3D
	body.teleport(parent3d.global_position)
	
	_tryPlaySound()
	
	emit_signal("onSend", body, parent3d)
	destTeleport.emit_signal("onReceive", body)


static func getAvailabeTags(body: Node3D) -> PackedStringArray:
	var result: PackedStringArray = []
	
	body.get_tree().get_nodes_in_group("Teleport").all(
		func (node: Node) -> bool:
			if !node.tag.is_empty():
				result.push_back(node.tag)
			return true
	)
	
	return result
