extends Node3D

const _PITCH_MAX: float = PI * 0.49
const _MOUSE_SENS_X: float = 0.002
const _MOUSE_SENS_Y: float = 0.002
const _UNZOOM_MAX: float = 4.0
var _TP_LIST: PackedStringArray = [
	"gdtricks-hub",
	"gdtricks-agtricks-1", "gdtricks-agtricks-2", "gdtricks-agtricks-3",
	"gdtricks-agtricks-4", "gdtricks-agtricks-5",
	"gdtricks-destructo-1", "gdtricks-destructo-2", "gdtricks-destructo-3",
	"gdtricks-destructo-4", "gdtricks-destructo-5", "gdtricks-destructo-6",
	"gdtricks-destructo-7", "gdtricks-destructo-8", "gdtricks-destructo-9",
	"gdtricks-destructo-10",
]

var _pawn: Node3D = null
var _current_tp_index: int = 0

@onready var _camera_3d: Camera3D = $Head/Camera3D
@onready var _head: Node3D = $Head
@onready var _esc_overlay: Control = $EscOverlay
@onready var _hud: Control = $Hud
@onready var _fullscreen: Button = $EscOverlay/CenterContainer/Column/Row/Fullscreen
@onready var _windowed: Button = $EscOverlay/CenterContainer/Column/Row/Windowed
@onready var _quit: Button = $EscOverlay/CenterContainer/Column/Row/Quit
@onready var _bar_speed: ProgressBar = $Hud/CenterContainer/TextureRect/BarSpeed
@onready var _button_next: Button = $EscOverlay/CenterContainer/Column/ButtonNext
@onready var _button_prev: Button = $EscOverlay/CenterContainer/Column/ButtonPrev
@onready var _audio_teleport: AudioStreamPlayer = $AudioTeleport


func _ready() -> void:
	_esc_overlay.visible = false
	_hud.visible = true
	
	var is_full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED
	_fullscreen.visible = !is_full
	_windowed.visible = is_full
	_fullscreen.pressed.connect(func () -> void: _set_fullscreen(true))
	_windowed.pressed.connect(func () -> void: _set_fullscreen(false))
	_quit.pressed.connect(func () -> void: get_tree().quit())
	
	_button_next.pressed.connect(_tp_to_next)
	_button_prev.pressed.connect(_tp_to_prev)


func _tp_delta(plus_minus_one: int) -> void:
	if !_pawn:
		return
	
	var next: int = _current_tp_index + plus_minus_one;
	_current_tp_index = (next + _TP_LIST.size()) % _TP_LIST.size();
	var teleports: Array[Node] = get_tree().get_nodes_in_group("Teleport")
	var wanted_tag: String = _TP_LIST[_current_tp_index]
	for teleport: Node in teleports:
		if teleport.tag != wanted_tag:
			continue
		var tp_parent := teleport.get_parent() as Node3D;
		if tp_parent:
			_pawn.teleport(tp_parent.global_position)
			_audio_teleport.play()


func _tp_to_next() -> void:
	_tp_delta(1)


func _tp_to_prev() -> void:
	_tp_delta(-1)


func possess(pawn: Node3D) -> void:
	if !pawn.has_signal("moved"):
		push_error("Pawn must have signal 'moved(pos: Vector3, head_y: float)'.")
	
	if _pawn:
		_pawn.moved.disconnect(_handle_move)
	
	_pawn = pawn
	_pawn.moved.connect(_handle_move)
	
	global_position = _pawn.global_position + Vector3.UP * _pawn.head_y
	_pawn.head_basis = _head.global_transform.basis


func _set_fullscreen(is_full: bool) -> void:
	_fullscreen.visible = !is_full
	_windowed.visible = is_full
	if is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _handle_move(pos: Vector3, head_y: float) -> void:
	global_position = pos + Vector3.UP * head_y


func _process(_dt: float) -> void:
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("Esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_captured else Input.MOUSE_MODE_CAPTURED
		is_captured = !is_captured
		_esc_overlay.visible = !is_captured
		_hud.visible = is_captured
	
	if !_pawn:
		return
	
	_bar_speed.value = min(1.0, _pawn.speed * 0.04)
	
	if !is_captured:
		_pawn.wish_axis = Vector3.ZERO
		return
	
	_pawn.wish_axis = (
		Vector3.FORWARD * Input.get_axis("Forward", "Back")
		+ Vector3.LEFT * Input.get_axis("Left", "Right")
		+ Vector3.UP * Input.get_axis("Duck", "Jump")
	)
	
	if _pawn.hull == "Swim":
		_pawn.wish_axis.y = Vector3.UP * Input.get_axis("Duck", "Jump")
	else:
		_pawn.wish_axis.y = 1.0 if Input.is_action_pressed("Jump") else 0.0
		
		if Input.is_action_just_pressed("Duck"):
			_pawn.hull = "Crouch"
		elif Input.is_action_just_released("Duck"):
			_pawn.hull = "Walk"
	
	if Input.is_action_just_released("Zoom"):
		_zoom();
	elif Input.is_action_just_released("Unzoom"):
		_unzoom();


func _zoom() -> void:
	_camera_3d.position.z *= 0.9;
	if _camera_3d.position.z < 1.0:
		_camera_3d.position.z = 0.0;


func _unzoom() -> void:
	if _camera_3d.position.z< 2.0:
		_camera_3d.position.z = 2.0;
	else:
		_camera_3d.position.z = min(
			_camera_3d.position.z * 1.1,
			_UNZOOM_MAX,
		);


func _rotate_look(dx: float, dy: float) -> void:
	rotate_y(-dx * _MOUSE_SENS_X)
	_head.rotation.x = clampf(
		_head.rotation.x - dy * _MOUSE_SENS_Y, -_PITCH_MAX, _PITCH_MAX,
	)
	
	if _pawn:
		_pawn.head_basis = _head.global_transform.basis


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if !(event is InputEventMouseMotion):
		return
	
	var event_motion: InputEventMouseMotion = event
	_rotate_look(event_motion.relative.x, event_motion.relative.y)
