extends Node3D

const _PITCH_MAX: float = PI * 0.49
const _MOUSE_SENS_X: float = 0.003
const _MOUSE_SENS_Y: float = 0.003

var pawn: Node3D = null

@onready var _camera_3d: Camera3D = $Camera3D


func _process(_dt: float) -> void:
	if !pawn:
		return
	
	global_position = pawn.global_position + Vector3.UP * pawn.head_y
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		pawn.wish_axis = Vector3.ZERO
		return
	
	pawn.wish_axis = (
		Vector3.FORWARD * Input.get_axis("Forward", "Back")
		+ Vector3.LEFT * Input.get_axis("Left", "Right")
		+ Vector3.UP * Input.get_axis("Duck", "Jump")
	)
	
	pawn.head_basis = _camera_3d.global_transform.basis


func _rotate_look(dx: float, dy: float) -> void:
	rotate_y(-dx * _MOUSE_SENS_X)
	_camera_3d.rotation.x = clampf(
		_camera_3d.rotation.x - dy * _MOUSE_SENS_Y,
		-_PITCH_MAX,
		_PITCH_MAX,
	)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if !(event is InputEventMouseMotion):
		return
	
	var event_motion: InputEventMouseMotion = event
	_rotate_look(event_motion.relative.x, event_motion.relative.y)
