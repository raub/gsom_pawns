extends Node
class_name GsomStart


var pos: Vector3 = Vector3.ZERO:
	get:
		var parent3d: Node3D = self.get_parent() as Node3D;
		if !parent3d:
			return Vector3.ZERO;
		return parent3d.global_position;

func _ready() -> void:
	add_to_group("Start");
