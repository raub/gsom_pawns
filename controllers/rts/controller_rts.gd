extends Node3D
class_name ControllerRts

signal switched_controller(controller_kind: String)

const __CHAR_UNIT := preload("../../characters/unit/char_unit.gd")

const __SCENE_DECAL_SELECT := preload("./decal_select.tscn")
const __SCENE_HEALTH_BAR := preload("./health_bar.tscn")
const __HEALTH_BARS_GAIN: int = 16
const __MAX_BATCH_SIZE: int = 12
const __RAY_LENGTH: float = 30.0

const __PAN_SENS := Vector2(0.01, 0.01)
const __SCROLL_SPEED := Vector2(10.0, 10.0)

const __ZOOM_MIN: float = -2.0
const __ZOOM_MAX: float = 1.0

const __PAN_MIN := Vector2(-41, -45)
const __PAN_MAX := Vector2(47, 39)
const __PAN_SIZE := Vector2(__PAN_MAX.x - __PAN_MIN.x, __PAN_MAX.y - __PAN_MIN.y)


var __is_focused: bool = false
@export var is_focused: bool = false:
	get:
		return __is_focused
	set(v):
		__is_focused = v
		__assign_is_focused()
		__adjust_health_bars()


var __pawns: Array[GsomPawn] = []
var __zoom_offset: float = 0.0

var __is_selecting: bool = false
var __selection_start: Vector3 = Vector3.ZERO
var __select_decals: Array[Decal] = []
var __health_bars: Array[HealthBar] = []

# These are not Input actions because we need to block the input by HUD when necessary
var __is_select_pressed: bool = false
var __is_action_pressed: bool = false
var __team: String = "team1"

@onready var __esc_overlay: EscOverlay = $EscOverlay
@onready var __hud_rts: HudRts = $HudRts
@onready var __camera: Camera3D = $Camera3D
@onready var __pool_decals_select: Node = $PoolDecalsSelect
@onready var __pool_health_bars: Node = $PoolHealthBars


func _ready() -> void:
	__esc_overlay.visible = false
	__hud_rts.visible = true
	
	__esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	
	__esc_overlay.switched_team.connect(__switch_team)
	
	__hud_rts.panned.connect(__handle_pan)
	__hud_rts.pressed_map.connect(__handle_map)
	
	__register_actions()
	__assign_is_focused()
	
	for _i: int in range(__MAX_BATCH_SIZE):
		var decal: Node3D = __SCENE_DECAL_SELECT.instantiate()
		__pool_decals_select.add_child(decal)
		decal.visible = false
		__select_decals.append(decal)
	
	__adjust_health_bars()


func __adjust_health_bars() -> void:
	var units: Array[GsomPawn] = __CHAR_UNIT.get_units()
	var unit_count: int = units.size()
	var current_count: int = __health_bars.size()
	
	while current_count < unit_count:
		for _i: int in range(__HEALTH_BARS_GAIN):
			var bar: HealthBar = __SCENE_HEALTH_BAR.instantiate()
			__pool_health_bars.add_child(bar)
			__health_bars.append(bar)
		current_count += __HEALTH_BARS_GAIN
	
	for i: int in range(current_count):
		var bar: HealthBar = __health_bars[i]
		if i >= unit_count:
			bar.visible = false
			continue
		bar.visible = __is_focused
		bar.position = units[i].position + Vector3.UP * 1.2
		bar.is_friendly = units[i].get_trait("team", "none") == __team



func _process(dt: float) -> void:
	if !__is_focused:
		return
	
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if Input.is_action_just_pressed("RTS_Esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_captured else Input.MOUSE_MODE_CONFINED
		is_captured = !is_captured
		__esc_overlay.visible = !is_captured
		__hud_rts.visible = is_captured
	
	if !is_captured:
		__is_selecting = false
		__selection_start = Vector3.ZERO
		return
	
	# Don't do silly stuff while map is being panned
	if Input.is_action_pressed("RTS_Pan"):
		return
	
	if __hud_rts.wish_scroll.length_squared() > 0.001:
		var pox_xz := Vector2(__camera.position.x, __camera.position.z)
		pox_xz = pox_xz + __hud_rts.wish_scroll * dt * __SCROLL_SPEED
		__camera.position.x = clampf(pox_xz.x, __PAN_MIN.x, __PAN_MAX.x)
		__camera.position.z = clampf(pox_xz.y, __PAN_MIN.y, __PAN_MAX.y)
		__hud_rts.move_map_screen((pox_xz - __PAN_MIN) / __PAN_SIZE)
		return
	
	if Input.is_action_just_released("RTS_Zoom"):
		__zoom()
	elif Input.is_action_just_released("RTS_Unzoom"):
		__unzoom()


func __switch_team(team_name: String) -> void:
	__pawns = []
	__team = team_name
	__update_decals()
	__adjust_health_bars()


func _physics_process(_dt: float) -> void:
	if !__is_focused:
		return
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if !is_captured:
		return
	
	__physics_process_pick()
	
	if __is_selecting:
		var unproj_start: Vector2 = __camera.unproject_position(__selection_start)
		var unproj_end: Vector2 = __hud_rts.get_global_mouse_position()
		__hud_rts.set_selection(unproj_start, unproj_end)
	else:
		__hud_rts.set_selection(Vector2(-10, -10), Vector2(-5, -5))
	
	__update_decals()
	__adjust_health_bars()
	
	__physics_process_follow()


func _unhandled_input(_event: InputEvent) -> void:
	if !__is_focused:
		return
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CONFINED
	if !is_captured:
		return
	
	__is_select_pressed = Input.is_action_pressed("RTS_Pick")
	__is_action_pressed = Input.is_action_pressed("RTS_Action")
	__hud_rts.accept_event()


func __update_decals() -> void:
	for i: int in range(__MAX_BATCH_SIZE):
		var decal: Node3D = __select_decals[i]
		if i >= __pawns.size():
			decal.visible = false
			continue
		decal.visible = true
		decal.position = __pawns[i].position


func __physics_process_pick() -> void:
	if !__is_selecting and __is_select_pressed:
		var result: Dictionary = __physics_process_pick_ray()
		if !result.has("position"):
			return
		__is_selecting = true
		__selection_start = result.position
		return
	
	if __is_selecting and !__is_select_pressed:
		__is_selecting = false
		var result: Dictionary = __physics_process_pick_ray()
		var _selection_end: Vector3 = result.position
		var diff: Vector3 = _selection_end - __selection_start
		
		# Point case
		if diff.length_squared() < 1:
			__fetch_pawns_from_colliders([result])
			return
		
		var result_box: Array[Dictionary] = __physics_process_pick_shape(
			__selection_start,
			_selection_end,
		)
		__fetch_pawns_from_colliders(result_box)
		return


func __physics_process_follow() -> void:
	if !__pawns.size() or !__is_action_pressed:
		return
	
	var result: Dictionary = __physics_process_pick_ray()
	var pawn_target: GsomPawn = __fetch_pawn(result)
	
	for pawn: GsomPawn in __pawns:
		if pawn_target and pawn_target.get_trait("team", "none") != __team:
			pawn.set_action("attack", pawn)
		elif result.position:
			pawn.set_action("move", result.position)


func __fetch_pawn(result: Dictionary) -> GsomPawn:
	if !result.has("collider"):
		return null
	
	var collider: Node = result.collider
	var parent: Node = collider.get_parent()
	if parent is GsomPawn:
		return parent
	
	return null


func __fetch_pawns_from_colliders(results: Array[Dictionary]) -> void:
	__pawns = []
	for result: Dictionary in results:
		var parent: GsomPawn = __fetch_pawn(result)
		if parent and parent.get_trait("team", "none") == __team:
			__pawns.append(parent)
	__update_decals()


func __physics_process_pick_ray() -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mousepos: Vector2 = get_viewport().get_mouse_position()
	
	var origin: Vector3 = __camera.project_ray_origin(mousepos)
	var end: Vector3 = origin + __camera.project_ray_normal(mousepos) * __RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 0x102 # Floor and Pawns
	
	var result: Dictionary = space_state.intersect_ray(query)
	return result


func __physics_process_pick_shape(start: Vector3, end: Vector3) -> Array[Dictionary]:
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


func __handle_pan(dxy: Vector2) -> void:
	var pox_xz := Vector2(__camera.position.x, __camera.position.z)
	pox_xz = pox_xz - dxy * __PAN_SENS
	__camera.position.x = clampf(pox_xz.x, __PAN_MIN.x, __PAN_MAX.x)
	__camera.position.z = clampf(pox_xz.y, __PAN_MIN.y, __PAN_MAX.y)
	__hud_rts.move_map_screen((pox_xz - __PAN_MIN) / __PAN_SIZE)


func __handle_map(xy_t: Vector2) -> void:
	var pox_xz: Vector2 = __PAN_MIN + xy_t * __PAN_SIZE
	
	if Input.is_action_pressed("RTS_Action") and __pawns.size():
		for pawn: GsomPawn in __pawns:
			pawn.set_action("move", Vector3(pox_xz.x, 0, pox_xz.y))
		return
	
	__hud_rts.move_map_screen(xy_t)
	__camera.position.x = pox_xz.x
	__camera.position.z = pox_xz.y


func __assign_is_focused() -> void:
	__is_selecting = false
	__selection_start = Vector3.ZERO
	
	if __camera:
		__camera.current = __is_focused
	
	if __esc_overlay:
		__esc_overlay.visible = __is_focused
	
	if __hud_rts:
		__hud_rts.visible = false
	
	var units: Array = __CHAR_UNIT.get_units()
	var unit_count: int = units.size()
	var current_count: int = __health_bars.size()
	for i: int in range(current_count):
		var bar: Node3D = __health_bars[i]
		if i >= unit_count:
			bar.visible = false
			continue
		bar.visible = __is_focused


func __zoom() -> void:
	__zoom_offset = maxf(__zoom_offset - 0.2, __ZOOM_MIN)
	__camera.position.y = 5.5 +__zoom_offset


func __unzoom() -> void:
	__zoom_offset = minf(__zoom_offset + 0.2, __ZOOM_MAX)
	__camera.position.y = 5.5 +__zoom_offset


func __register_actions() -> void:
	InputMap.add_action("RTS_Follow")
	var key_space := InputEventKey.new()
	key_space.keycode = KEY_SPACE
	InputMap.action_add_event("RTS_Follow", key_space)
	
	InputMap.add_action("RTS_Pick")
	var key_pick := InputEventMouseButton.new()
	key_pick.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("RTS_Pick", key_pick)
	
	InputMap.add_action("RTS_Action")
	var key_action := InputEventMouseButton.new()
	key_action.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("RTS_Action", key_action)
	
	InputMap.add_action("RTS_Pan")
	var key_pan := InputEventMouseButton.new()
	key_pan.button_index = MOUSE_BUTTON_MIDDLE
	InputMap.action_add_event("RTS_Pan", key_pan)
	
	InputMap.add_action("RTS_Zoom")
	var key_zoom := InputEventMouseButton.new()
	key_zoom.button_index = MOUSE_BUTTON_WHEEL_UP
	InputMap.action_add_event("RTS_Zoom", key_zoom)
	
	InputMap.add_action("RTS_Unzoom")
	var key_unzoom := InputEventMouseButton.new()
	key_unzoom.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("RTS_Unzoom", key_unzoom)
	
	InputMap.add_action("RTS_Esc")
	var key_esc := InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	InputMap.action_add_event("RTS_Esc", key_esc)
