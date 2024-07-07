extends Node3D

signal switched_character(character_kind: String)
signal switched_controller(controller_kind: String)

const _PITCH_MAX: float = PI * 0.49
const _MOUSE_SENS_X: float = 0.002
const _MOUSE_SENS_Y: float = 0.002
const _UNZOOM_MAX: float = 4.0

var kind: String = "unknown"

var _is_focused: bool = false
@export var is_focused: bool = false:
	get:
		return _is_focused
	set(v):
		_is_focused = v
		_assign_is_focused()

var _pawn: GsomPawn = null

@onready var _audio_teleport: AudioStreamPlayer = $AudioTeleport
@onready var _camera_3d: Camera3D = $Head/Camera3D
@onready var _head: Node3D = $Head
@onready var _esc_overlay: Control = $EscOverlay
@onready var _hud: Control = $Hud
@onready var _bar_speed: ProgressBar = $Hud/CenterContainer/TextureRect/BarSpeed
@onready var _camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	_esc_overlay.visible = false
	_hud.visible = true
	
	_esc_overlay.switched_character.connect(
		func (new_kind: String) -> void: switched_character.emit(new_kind),
	)
	_esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	_esc_overlay.teleported.connect(_handle_teleport)
	
	_register_actions()
	_assign_is_focused()


func possess(pawn: GsomPawn) -> void:
	if !pawn.has_signal("moved"):
		push_error("Pawn must have signal 'moved(pos: Vector3, head_y: float)'.")
	
	if _pawn:
		_pawn.moved.disconnect(_handle_move)
		_pawn.moved_head.disconnect(_handle_move_head)
		_pawn.reset_actions()
	
	_pawn = pawn
	_pawn.moved.connect(_handle_move)
	_pawn.moved_head.connect(_handle_move_head)
	
	_head.position.y = _pawn.head_y
	_pawn.set_action("basis", _head.global_transform.basis)


func _assign_is_focused() -> void:
	if !_camera:
		return
	
	_camera.current = _is_focused
	_esc_overlay.visible = _is_focused
	_hud.visible = false


func _handle_teleport(pos: Vector3) -> void:
	if !_pawn:
		return
	
	_pawn.triggered.emit("teleport", pos)
	_audio_teleport.play()


func _handle_move(pos: Vector3) -> void:
	global_position = pos


func _handle_move_head(head_y: float) -> void:
	_head.position.y = head_y


func _process(_dt: float) -> void:
	if !_is_focused:
		return
	
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("FPS_Esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_captured else Input.MOUSE_MODE_CAPTURED
		is_captured = !is_captured
		_esc_overlay.visible = !is_captured
		_hud.visible = is_captured
	
	if !_pawn:
		return
	
	if kind == "vtol":
		_bar_speed.value = min(1.0, _pawn.linear_velocity.length() * 0.04)
	elif kind == "human":
		var velocity_xz: Vector2 = Vector2(_pawn.linear_velocity.x, _pawn.linear_velocity.z)
		_bar_speed.value = min(1.0, velocity_xz.length() * 0.04)
	else:
		_bar_speed.value = min(1.0, _pawn.linear_velocity.length() * 0.08)
	
	if !is_captured:
		_pawn.reset_actions()
		return
	
	_pawn.set_action("forward", Input.is_action_pressed("FPS_Forward"))
	_pawn.set_action("back", Input.is_action_pressed("FPS_Back"))
	_pawn.set_action("moveleft", Input.is_action_pressed("FPS_Left"))
	_pawn.set_action("moveright", Input.is_action_pressed("FPS_Right"))
	_pawn.set_action("jump", Input.is_action_pressed("FPS_Jump"))
	_pawn.set_action("duck", Input.is_action_pressed("FPS_Duck"))
	_pawn.set_action("sprint", Input.is_action_pressed("FPS_Sprint"))
	
	if Input.is_action_just_released("FPS_Zoom"):
		_zoom()
	elif Input.is_action_just_released("FPS_Unzoom"):
		_unzoom()


func _zoom() -> void:
	_camera_3d.position.z *= 0.9
	if _camera_3d.position.z < 1.0:
		_camera_3d.position.z = 0.0


func _unzoom() -> void:
	if _camera_3d.position.z< 2.0:
		_camera_3d.position.z = 2.0
	else:
		_camera_3d.position.z = min(
			_camera_3d.position.z * 1.1,
			_UNZOOM_MAX,
		)


func _rotate_look(dx: float, dy: float) -> void:
	rotate_y(-dx * _MOUSE_SENS_X)
	_head.rotation.x = clampf(
		_head.rotation.x - dy * _MOUSE_SENS_Y, -_PITCH_MAX, _PITCH_MAX,
	)
	
	if _pawn:
		_pawn.set_action("basis", _head.global_transform.basis)


func _unhandled_input(event: InputEvent) -> void:
	if !_is_focused:
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if !(event is InputEventMouseMotion):
		return
	
	var event_motion: InputEventMouseMotion = event
	_rotate_look(event_motion.relative.x, event_motion.relative.y)


func _register_actions() -> void:
	InputMap.add_action("FPS_Duck")
	var keyCtrl := InputEventKey.new()
	keyCtrl.keycode = KEY_CTRL
	InputMap.action_add_event("FPS_Duck", keyCtrl)
	
	InputMap.add_action("FPS_Jump")
	var keySpace := InputEventKey.new()
	keySpace.keycode = KEY_SPACE
	InputMap.action_add_event("FPS_Jump", keySpace)
	
	InputMap.add_action("FPS_Forward")
	var keyW := InputEventKey.new()
	keyW.keycode = KEY_W
	InputMap.action_add_event("FPS_Forward", keyW)
	
	InputMap.add_action("FPS_Back")
	var keyS := InputEventKey.new()
	keyS.keycode = KEY_S
	InputMap.action_add_event("FPS_Back", keyS)
	
	InputMap.add_action("FPS_Left")
	var keyA := InputEventKey.new()
	keyA.keycode = KEY_A
	InputMap.action_add_event("FPS_Left", keyA)
	
	InputMap.add_action("FPS_Right")
	var keyD := InputEventKey.new()
	keyD.keycode = KEY_D
	InputMap.action_add_event("FPS_Right", keyD)
	
	InputMap.add_action("FPS_Zoom")
	var keyZoom := InputEventMouseButton.new()
	keyZoom.button_index = MOUSE_BUTTON_WHEEL_UP
	InputMap.action_add_event("FPS_Zoom", keyZoom)
	
	InputMap.add_action("FPS_Sprint")
	var keySprint := InputEventKey.new()
	keySprint.keycode = KEY_SHIFT
	InputMap.action_add_event("FPS_Sprint", keySprint)
	
	InputMap.add_action("FPS_Unzoom")
	var keyUnzoom := InputEventMouseButton.new()
	keyUnzoom.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("FPS_Unzoom", keyUnzoom)
	
	InputMap.add_action("FPS_Esc")
	var keyEsc := InputEventKey.new()
	keyEsc.keycode = KEY_ESCAPE
	InputMap.action_add_event("FPS_Esc", keyEsc)
