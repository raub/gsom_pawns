extends Node3D

signal switched_controller(controller_kind: String)

const _CHAR_UNIT: GDScript = preload("../../characters/unit/char_unit.gd")

const _SCENE_DECAL_SELECT: PackedScene = preload("./decal_select.tscn")
const _SCENE_HEALTH_BAR: PackedScene = preload("./health_bar.tscn")
const _HEALTH_BARS_GAIN: int = 16
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
		_adjust_health_bars()


var _pawns: Array[GsomPawn] = []
var _zoom_offset: float = 0.0

var _is_selecting: bool = false
var _selection_start: Vector3 = Vector3.ZERO
var _select_decals: Array[Decal] = []
var _health_bars: Array[Node] = []

# These are not Input actions because we need to block the input by HUD when necessary
var _is_select_pressed: bool = false
var _is_action_pressed: bool = false
var _team: String = "team1"

@onready var _esc_overlay: Control = $EscOverlay
@onready var _hud_rts: Control = $HudRts
@onready var _camera: Camera3D = $Camera3D
@onready var _pool_decals_select: Node = $PoolDecalsSelect
@onready var _pool_health_bars: Node = $PoolHealthBars


func _ready() -> void:
	_esc_overlay.visible = false
	_hud_rts.visible = true
	
	_esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	
	_esc_overlay.switched_team.connect(_switch_team)
	
	_hud_rts.panned.connect(_handle_pan)
	_hud_rts.pressed_map.connect(_handle_map)
	
	_register_actions()
	_assign_is_focused()
	
	for _i: int in range(_MAX_BATCH_SIZE):
		var decal: Node3D = _SCENE_DECAL_SELECT.instantiate()
		_pool_decals_select.add_child(decal)
		decal.visible = false
		_select_decals.append(decal)
	
	_adjust_health_bars()


func _adjust_health_bars() -> void:
	var units: Array = _CHAR_UNIT.get_units()
	var unit_count: int = units.size()
	var current_count: int = _health_bars.size()
	
	while current_count < unit_count:
		for _i: int in range(_HEALTH_BARS_GAIN):
			var bar: Node3D = _SCENE_HEALTH_BAR.instantiate()
			_pool_health_bars.add_child(bar)
			_health_bars.append(bar)
		current_count += _HEALTH_BARS_GAIN
	
	for i: int in range(current_count):
		var bar: Node3D = _health_bars[i]
		if i >= unit_count:
			bar.visible = false
			continue
		bar.visible = _is_focused
		bar.position = units[i].position + Vector3.UP * 1.2
		bar.is_friendly = units[i].get_trait("team", "none") == _team



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
	
	# Don't do silly stuff while map is being panned
	if Input.is_action_pressed("RTS_Pan"):
		return
	
	if _hud_rts.wish_scroll.length_squared() > 0.001:
		var pox_xz := Vector2(_camera.position.x, _camera.position.z)
		pox_xz = pox_xz + _hud_rts.wish_scroll * dt * _SCROLL_SPEED
		_camera.position.x = clamp(pox_xz.x, _PAN_MIN.x, _PAN_MAX.x)
		_camera.position.z = clamp(pox_xz.y, _PAN_MIN.y, _PAN_MAX.y)
		_hud_rts.move_map_screen((pox_xz - _PAN_MIN) / _PAN_SIZE)
		return
	
	if Input.is_action_just_released("RTS_Zoom"):
		_zoom()
	elif Input.is_action_just_released("RTS_Unzoom"):
		_unzoom()


func _switch_team(team_name: String) -> void:
	_pawns = []
	_team = team_name
	_update_decals()
	_adjust_health_bars()


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
	
	_update_decals()
	_adjust_health_bars()
	
	_physics_process_follow()


func _unhandled_input(_event: InputEvent) -> void:
	if !_is_focused:
		return
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if !is_captured:
		return
	
	_is_select_pressed = Input.is_action_pressed("RTS_Pick")
	_is_action_pressed = Input.is_action_pressed("RTS_Action")
	_hud_rts.accept_event()


func _update_decals() -> void:
	for i: int in range(_MAX_BATCH_SIZE):
		var decal: Node3D = _select_decals[i]
		if i >= _pawns.size():
			decal.visible = false
			continue
		decal.visible = true
		decal.position = _pawns[i].position


func _physics_process_pick() -> void:
	if !_is_selecting and _is_select_pressed:
		var result: Dictionary = _physics_process_pick_ray()
		if !result.has("position"):
			return
		_is_selecting = true
		_selection_start = _physics_process_pick_ray().position
		return
	
	if _is_selecting and !_is_select_pressed:
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


func _physics_process_follow() -> void:
	if !_pawns.size() or !_is_action_pressed:
		return
	
	var result: Dictionary = _physics_process_pick_ray()
	var pawn_target: GsomPawn = _fetch_pawn(result)
	
	for pawn: GsomPawn in _pawns:
		if pawn_target and pawn_target.get_trait("team", "none") != _team:
			pawn.set_action("attack", pawn)
		elif result.position:
			pawn.set_action("move", result.position)


func _fetch_pawn(result: Dictionary) -> GsomPawn:
	if !result.has("collider"):
		return null
	var collider := result.collider as Node
	var parent := collider.get_parent() as GsomPawn
	return parent


func _fetch_pawns_from_colliders(results: Array[Dictionary]) -> void:
	_pawns = []
	for result: Dictionary in results:
		var parent: GsomPawn = _fetch_pawn(result)
		if parent and parent.get_trait("team", "none") == _team:
			_pawns.append(parent)
	_update_decals()


func _physics_process_pick_ray() -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mousepos: Vector2 = get_viewport().get_mouse_position()
	
	var origin: Vector3 = _camera.project_ray_origin(mousepos)
	var end: Vector3 = origin + _camera.project_ray_normal(mousepos) * _RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 0x102 # Floor and Pawns
	
	var result: Dictionary = space_state.intersect_ray(query)
	return result


func _physics_process_pick_shape(start: Vector3, end: Vector3) -> Array[Dictionary]:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	
	var shape_rid: RID = PhysicsServer3D.box_shape_create()
	PhysicsServer3D.shape_set_data(
		shape_rid,
		Vector3(absf(end.x - start.x) * 0.5, 5.0, absf(end.z - start.z) * 0.5)
	)
	
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape_rid = shape_rid
	params.transform.origin = (start + end) * 0.5
	params.collision_mask = 0x100 # Pawns only
	
	var result: Array[Dictionary] = space_state.intersect_shape(params, 16)
	
	PhysicsServer3D.free_rid(shape_rid)
	
	return result


func _handle_pan(dxy: Vector2) -> void:
	var pox_xz := Vector2(_camera.position.x, _camera.position.z)
	pox_xz = pox_xz - dxy * _PAN_SENS
	_camera.position.x = clamp(pox_xz.x, _PAN_MIN.x, _PAN_MAX.x)
	_camera.position.z = clamp(pox_xz.y, _PAN_MIN.y, _PAN_MAX.y)
	_hud_rts.move_map_screen((pox_xz - _PAN_MIN) / _PAN_SIZE)


func _handle_map(xy_t: Vector2) -> void:
	var pox_xz: Vector2 = _PAN_MIN + xy_t * _PAN_SIZE
	
	if Input.is_action_pressed("RTS_Action") and _pawns.size():
		for pawn: GsomPawn in _pawns:
			pawn.set_action("move", Vector3(pox_xz.x, 0, pox_xz.y))
		return
	
	_hud_rts.move_map_screen(xy_t)
	_camera.position.x = pox_xz.x
	_camera.position.z = pox_xz.y


func _assign_is_focused() -> void:
	_is_selecting = false
	_selection_start = Vector3.ZERO
	
	if _camera:
		_camera.current = _is_focused
	
	if _esc_overlay:
		_esc_overlay.visible = _is_focused
	
	if _hud_rts:
		_hud_rts.visible = false
	
	var units: Array = _CHAR_UNIT.get_units()
	var unit_count: int = units.size()
	var current_count: int = _health_bars.size()
	for i: int in range(current_count):
		var bar: Node3D = _health_bars[i]
		if i >= unit_count:
			bar.visible = false
			continue
		bar.visible = _is_focused


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
