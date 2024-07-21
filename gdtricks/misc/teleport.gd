extends GsomPawnTrigger

@export var tag: String = ""
@export var dest: String = ""


static var _teleports: Array[Node] = []


func _ready() -> void:
	_teleports.append(self)
	_attach()


func _exit_tree() -> void:
	_teleports.erase(self)


func _trigger_enter(pawn: GsomPawn) -> void:
	var teleports: Array = _teleports.filter(
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
	
	pawn.triggered.emit("teleport", { "pos": parent_3d.global_position })
	
	_try_play_sound()


func _try_play_sound() -> void:
	for child: Node in get_children():
		if child.has_method("play"):
			child.call("play")
			break
