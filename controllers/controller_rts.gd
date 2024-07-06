extends Node3D

signal switched_controller(controller_kind: String)


const _PAN_SENS_X: float = 0.002
const _PAN_SENS_Y: float = 0.002

const _SCROLL_SPEED_X: float = 0.002
const _SCROLL_SPEED_Y: float = 0.002

const _ZOOM_MIN: float = -4.0
const _ZOOM_MAX: float = 2.0


var _is_focused: bool = false
@export var is_focused: bool = false:
	get:
		return _is_focused
	set(v):
		_is_focused = v
		_assignIsFocused()


var _pawns: Array[GsomPawn] = []
var _zoom_offset: float = 0.0


@onready var _esc_overlay: Control = $EscOverlay
@onready var _hud: Control = $Hud
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_esc_overlay.visible = false
	_hud.visible = true
	
	_esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	
	_register_actions()
	_assignIsFocused()


func _process(_dt: float) -> void:
	if !_is_focused:
		return
	
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if Input.is_action_just_pressed("FPS_Esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_captured else Input.MOUSE_MODE_CONFINED
		is_captured = !is_captured
		_esc_overlay.visible = !is_captured
		_hud.visible = is_captured
	
	if !is_captured:
		return
	
	if Input.is_action_just_released("FPS_Zoom"):
		_zoom()
	elif Input.is_action_just_released("FPS_Unzoom"):
		_unzoom()


func _assignIsFocused() -> void:
	if !_camera:
		return
	
	_camera.current = _is_focused
	_esc_overlay.visible = _is_focused
	_hud.visible = false


func _zoom() -> void:
	_zoom_offset = max(_zoom_offset - 0.2, _ZOOM_MIN)
	position.y = 5.5 +_zoom_offset


func _unzoom() -> void:
	_zoom_offset = max(_zoom_offset + 0.2, _ZOOM_MIN)
	position.y = 5.5 +_zoom_offset


func _register_actions() -> void:
	InputMap.add_action("RTS_Follow")
	var keySpace := InputEventKey.new()
	keySpace.keycode = KEY_SPACE
	InputMap.action_add_event("RTS_Follow", keySpace)
	
	InputMap.add_action("RTS_Zoom")
	var keyZoom := InputEventMouseButton.new()
	keyZoom.button_index = MOUSE_BUTTON_WHEEL_UP
	InputMap.action_add_event("RTS_Zoom", keyZoom)
	
	InputMap.add_action("RTS_Unzoom")
	var keyUnzoom := InputEventMouseButton.new()
	keyUnzoom.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("RTS_Unzoom", keyUnzoom)
	
	InputMap.add_action("RTS_Esc")
	var keyEsc := InputEventKey.new()
	keyEsc.keycode = KEY_ESCAPE
	InputMap.action_add_event("RTS_Esc", keyEsc)
