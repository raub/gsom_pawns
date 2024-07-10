extends Node3D

signal switched_controller(controller_kind: String)

const _CHAR_UNIT: GDScript = preload("../../characters/unit/char_unit.gd")

const _SCENE_DECAL_SELECT: PackedScene = preload("./decal_select.tscn")
const _MAX_BATCH_SIZE: int = 12
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


var _pawns: Array[GsomPawn] = []
var _zoom_offset: float = 0.0

var _is_selecting: bool = false
var _selection_start: Vector3 = Vector3.ZERO
var _select_decals: Array[Decal] = []


@onready var _esc_overlay: Control = $EscOverlay
@onready var _hud_rts: Control = $HudRts
@onready var _camera: Camera3D = $Camera3D
@onready var _area_select: Area3D = $AreaSelect
@onready var _shape_select: CollisionShape3D = $AreaSelect/ShapeSelect
@onready var _pool_decals_select: Node = $PoolDecalsSelect


func _ready() -> void:
	_esc_overlay.visible = false
	_hud_rts.visible = true
	
	_esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	
	_hud_rts.panned.connect(_pan)
	
	_register_actions()
	_assign_is_focused()
	
	for _i: int in range(_MAX_BATCH_SIZE):
		var decal = _SCENE_DECAL_SELECT.instantiate()
		_pool_decals_select.add_child(decal)
		decal.visible = false
		_select_decals.append(decal)
	
	prints("units", _CHAR_UNIT.get_units())


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
		_is_selecting = false
		_selection_start = Vector3.ZERO
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


func _physics_process(_dt: float) -> void:
	if !_is_focused:
		return
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if !is_captured:
		return
	
	_physics_process_pick()
	
	if _is_selecting:
		var unproj_start: Vector2 = _camera.unproject_position(_selection_start)
		var unproj_end: Vector2 = _hud_rts.get_global_mouse_position()
		_hud_rts.set_selection(unproj_start, unproj_end)
	else:
		_hud_rts.set_selection(Vector2(-10, -10), Vector2(-5, -5))
	
	_physics_process_decals()


func _physics_process_decals() -> void:
	for i: int in range(_MAX_BATCH_SIZE):
		var decal = _select_decals[i]
		if i >= _pawns.size():
			decal.visible = false
			continue
		decal.visible = true
		decal.position = _pawns[i].position
	


func _physics_process_pick() -> void:
	if !_is_selecting and Input.is_action_pressed("RTS_Pick"):
		var result: Dictionary = _physics_process_pick_ray()
		if !result.position:
			return
		_is_selecting = true
		_selection_start = _physics_process_pick_ray().position
		return
	
	if _is_selecting and !Input.is_action_pressed("RTS_Pick"):
		_is_selecting = false
		var result: Dictionary = _physics_process_pick_ray()
		var _selection_end: Vector3 = result.position
		var diff: Vector3 = _selection_end - _selection_start
		
		# Point case
		if diff.length_squared() < 1:
			_fetch_pawns_from_colliders([result])
			return
		
		var result_box: Array[Dictionary] = _physics_process_pick_shape(_selection_start, _selection_end)
		_fetch_pawns_from_colliders(result_box)
		return


func _fetch_pawns_from_colliders(results: Array[Dictionary]) -> void:
	_pawns = []
	for result: Dictionary in results:
		if !result.collider:
			continue
		var collider := result.collider as Node
		var parent := collider.get_parent() as GsomPawn
		if !parent:
			continue
		_pawns.append(parent)


func _physics_process_pick_ray() -> Dictionary:
	var space_state = get_world_3d().direct_space_state
	var mousepos = get_viewport().get_mouse_position()
	
	var origin: Vector3 = _camera.project_ray_origin(mousepos)
	var end: Vector3 = origin + _camera.project_ray_normal(mousepos) * _RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	#query.collision_mask = 0x100
	
	var result = space_state.intersect_ray(query)
	return result


func _physics_process_pick_shape(start: Vector3, end: Vector3) -> Array[Dictionary]:
	#_area_select.transform = _camera.global_transform
	_area_select.transform.origin = (start + end) * 0.5
	var box := _shape_select.shape as BoxShape3D
	box.size = Vector3(abs(end.x - start.x), 5.0, abs(end.z - start.z))
	
	#return {}
	#
	var space_state = get_world_3d().direct_space_state
	#var query := PhysicsShapeQueryParameters3D.create(start, end)
	
	var shape_rid = PhysicsServer3D.box_shape_create()
	PhysicsServer3D.shape_set_data(
		shape_rid,
		Vector3(abs(end.x - start.x), 5.0, abs(end.z - start.z))
	)
	
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape_rid = shape_rid
	#params.transform = Transform3D(_camera.transform)
	params.transform.origin = (start + end) * 0.5
	params.collision_mask = 0x100
	
	# Execute physics queries here...
	var result = space_state.intersect_shape(params, 16)
	
	# Release the shape when done with physics queries.
	PhysicsServer3D.free_rid(shape_rid)
	
	return result


func _pan(dxy: Vector2) -> void:
	var pox_xz := Vector2(_camera.position.x, _camera.position.z)
	pox_xz = pox_xz - dxy * _PAN_SENS
	_camera.position.x = clamp(pox_xz.x, _PAN_MIN.x, _PAN_MAX.x)
	_camera.position.z = clamp(pox_xz.y, _PAN_MIN.y, _PAN_MAX.y)
	_hud_rts.move_map_screen((pox_xz - _PAN_MIN) / _PAN_SIZE)


func _assign_is_focused() -> void:
	_is_selecting = false
	_selection_start = Vector3.ZERO
	
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
