extends Node3D

signal switched_controller(controller_kind: String)

const _RAY_LENGTH: float = 30.0

const _PAN_SENS := Vector2(0.01, 0.01)
const _SCROLL_SPEED := Vector2(10.0, 10.0)

const _ZOOM_MIN: float = -2.0
const _ZOOM_MAX: float = 1.0

const _PAN_MIN := Vector2(-41, -45)
const _PAN_MAX := Vector2(47, 39)
const _PAN_SIZE := Vector2(_PAN_MAX.x - _PAN_MIN.x, _PAN_MAX.y - _PAN_MIN.y)


var _is_focused: bool = false
@export var is_focused: bool = false:
	get:
		return _is_focused
	set(v):
		_is_focused = v
		_assign_is_focused()


#var _pawns: Array[GsomPawn] = []
var _zoom_offset: float = 0.0


@onready var _esc_overlay: Control = $EscOverlay
@onready var _hud_rts: Control = $HudRts
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	_esc_overlay.visible = false
	_hud_rts.visible = true
	
	_esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	
	_hud_rts.panned.connect(_pan)
	
	_register_actions()
	_assign_is_focused()


func _process(dt: float) -> void:
	if !_is_focused:
		return
	
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if Input.is_action_just_pressed("RTS_Esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_captured else Input.MOUSE_MODE_CONFINED
		is_captured = !is_captured
		_esc_overlay.visible = !is_captured
		_hud_rts.visible = is_captured
	
	if !is_captured:
		return
	
	if Input.is_action_just_released("RTS_Zoom"):
		_zoom()
	elif Input.is_action_just_released("RTS_Unzoom"):
		_unzoom()
	
	if !Input.is_action_pressed("RTS_Pan"):
		var pox_xz := Vector2(_camera.position.x, _camera.position.z)
		pox_xz = pox_xz + _hud_rts.wish_scroll * dt * _SCROLL_SPEED
		_camera.position.x = clamp(pox_xz.x, _PAN_MIN.x, _PAN_MAX.x)
		_camera.position.z = clamp(pox_xz.y, _PAN_MIN.y, _PAN_MAX.y)
		_hud_rts.move_map_screen((pox_xz - _PAN_MIN) / _PAN_SIZE)


func _physics_process(delta):
	if !_is_focused:
		return
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if !is_captured:
		return
	
	if !Input.is_action_pressed("RTS_Pick"):
		return
	
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()

	var origin: Vector3 = _camera.project_ray_origin(mousepos)
	var end: Vector3 = origin + _camera.project_ray_normal(mousepos) * _RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = false

	var result = space_state.intersect_ray(query)
	prints("result", result)


func _pan(dxy: Vector2) -> void:
	var pox_xz := Vector2(_camera.position.x, _camera.position.z)
	pox_xz = pox_xz - dxy * _PAN_SENS
	_camera.position.x = clamp(pox_xz.x, _PAN_MIN.x, _PAN_MAX.x)
	_camera.position.z = clamp(pox_xz.y, _PAN_MIN.y, _PAN_MAX.y)
	_hud_rts.move_map_screen((pox_xz - _PAN_MIN) / _PAN_SIZE)


func _assign_is_focused() -> void:
	if !_camera:
		return
	
	_camera.current = _is_focused
	_esc_overlay.visible = _is_focused
	_hud_rts.visible = false


func _zoom() -> void:
	_zoom_offset = max(_zoom_offset - 0.2, _ZOOM_MIN)
	_camera.position.y = 5.5 +_zoom_offset


func _unzoom() -> void:
	_zoom_offset = min(_zoom_offset + 0.2, _ZOOM_MAX)
	_camera.position.y = 5.5 +_zoom_offset


func _register_actions() -> void:
	InputMap.add_action("RTS_Follow")
	var keySpace := InputEventKey.new()
	keySpace.keycode = KEY_SPACE
	InputMap.action_add_event("RTS_Follow", keySpace)
	
	InputMap.add_action("RTS_Pick")
	var keyPick := InputEventMouseButton.new()
	keyPick.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("RTS_Pick", keyPick)
	
	InputMap.add_action("RTS_Action")
	var keyAction := InputEventMouseButton.new()
	keyAction.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("RTS_Action", keyAction)
	
	InputMap.add_action("RTS_Pan")
	var keyPan := InputEventMouseButton.new()
	keyPan.button_index = MOUSE_BUTTON_MIDDLE
	InputMap.action_add_event("RTS_Pan", keyPan)
	
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
