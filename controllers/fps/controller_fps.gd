extends Node3D
class_name ControllerFps

signal switched_character(character_kind: String)
signal switched_controller(controller_kind: String)

const __PITCH_MAX: float = PI * 0.49
const __MOUSE_SENS_X: float = 0.002
const __MOUSE_SENS_Y: float = 0.002
const __UNZOOM_MAX: float = 4.0

var kind: String = "unknown"

var __is_focused: bool = false
@export var is_focused: bool = false:
	get:
		return __is_focused
	set(v):
		__is_focused = v
		__assign_is_focused()

var __pawn: GsomPawn = null

@onready var __audio_teleport: AudioStreamPlayer = $AudioTeleport
@onready var __camera_3d: Camera3D = $Head/Camera3D
@onready var __head: Node3D = $Head
@onready var __esc_overlay: EscOverlay = $EscOverlay
@onready var __hud: Control = $Hud
@onready var __bar_speed: ProgressBar = $Hud/CenterContainer/TextureRect/BarSpeed
@onready var __camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	__esc_overlay.visible = false
	__hud.visible = true
	
	__esc_overlay.switched_character.connect(
		func (new_kind: String) -> void: switched_character.emit(new_kind),
	)
	__esc_overlay.switched_controller.connect(
		func (new_kind: String) -> void: switched_controller.emit(new_kind),
	)
	__esc_overlay.teleported.connect(__handle_teleport)
	
	__register_actions()
	__assign_is_focused()


func possess(pawn: GsomPawn) -> void:
	if !pawn.has_signal("moved"):
		push_error("Pawn must have signal 'moved(pos: Vector3, head_y: float)'.")
	
	if __pawn:
		var parent: Node = __pawn.get_parent()
		if parent is Node3D:
			var parent3d: Node3D = parent
			parent3d.visible = true
		
		__pawn.moved.disconnect(__handle_move)
		__pawn.moved_head.disconnect(__handle_move_head)
		__pawn.reset_actions()
	
	__pawn = pawn
	__pawn.moved.connect(__handle_move)
	__pawn.moved_head.connect(__handle_move_head)
	
	__head.position.y = __pawn.head_y
	__pawn.set_action("basis", __head.global_transform.basis)
	
	__update_pawn_visibility()


func __assign_is_focused() -> void:
	if !__camera:
		return
	
	__camera.current = __is_focused
	__esc_overlay.visible = __is_focused
	__hud.visible = false


func __handle_teleport(pos: Vector3) -> void:
	if !__pawn:
		return
	
	__pawn.trigger("teleport", { "pos": pos })
	__audio_teleport.play()


func __handle_move(pos: Vector3) -> void:
	global_position = pos


func __handle_move_head(head_y: float) -> void:
	__head.position.y = head_y


func _process(_dt: float) -> void:
	if !__is_focused:
		return
	
	var is_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("FPS_Esc"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_captured else Input.MOUSE_MODE_CAPTURED
		is_captured = !is_captured
		__esc_overlay.visible = !is_captured
		__hud.visible = is_captured
	
	if !__pawn:
		return
	
	if kind == "vtol":
		__bar_speed.value = minf(1.0, __pawn.linear_velocity.length() * 0.01)
	elif kind == "human":
		var velocity_xz: Vector2 = Vector2(__pawn.linear_velocity.x, __pawn.linear_velocity.z)
		__bar_speed.value = minf(1.0, velocity_xz.length() * 0.04)
	else:
		__bar_speed.value = minf(1.0, __pawn.linear_velocity.length() * 0.08)
	
	if !is_captured:
		__pawn.reset_actions()
		return
	
	__pawn.set_action("forward", Input.is_action_pressed("FPS_Forward"))
	__pawn.set_action("back", Input.is_action_pressed("FPS_Back"))
	__pawn.set_action("moveleft", Input.is_action_pressed("FPS_Left"))
	__pawn.set_action("moveright", Input.is_action_pressed("FPS_Right"))
	__pawn.set_action("jump", Input.is_action_pressed("FPS_Jump"))
	__pawn.set_action("duck", Input.is_action_pressed("FPS_Duck"))
	__pawn.set_action("sprint", Input.is_action_pressed("FPS_Sprint"))
	
	if Input.is_action_just_released("FPS_Zoom"):
		__zoom()
	elif Input.is_action_just_released("FPS_Unzoom"):
		__unzoom()


func __update_pawn_visibility() -> void:
	if !__pawn:
		return
	
	var parent: Node = __pawn.get_parent()
	if parent is Node3D:
		var parent3d: Node3D = parent
		parent3d.visible = __camera_3d.position.z > 0.5


func __zoom() -> void:
	__camera_3d.position.z *= 0.9
	if __camera_3d.position.z < 1.0:
		__camera_3d.position.z = 0.0
	
	__update_pawn_visibility()


func __unzoom() -> void:
	if __camera_3d.position.z< 2.0:
		__camera_3d.position.z = 2.0
	else:
		__camera_3d.position.z = minf(__camera_3d.position.z * 1.1, __UNZOOM_MAX)
	
	__update_pawn_visibility()


func __rotate_look(dx: float, dy: float) -> void:
	rotate_y(-dx * __MOUSE_SENS_X)
	__head.rotation.x = clampf(
		__head.rotation.x - dy * __MOUSE_SENS_Y, -__PITCH_MAX, __PITCH_MAX,
	)
	
	if __pawn:
		__pawn.set_action("basis", __head.global_transform.basis)


func _unhandled_input(event: InputEvent) -> void:
	if !__is_focused:
		return
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if !(event is InputEventMouseMotion):
		return
	
	var event_motion: InputEventMouseMotion = event
	__rotate_look(event_motion.relative.x, event_motion.relative.y)


func __register_actions() -> void:
	InputMap.add_action("FPS_Duck")
	var key_ctrl := InputEventKey.new()
	key_ctrl.keycode = KEY_CTRL
	InputMap.action_add_event("FPS_Duck", key_ctrl)
	
	InputMap.add_action("FPS_Jump")
	var key_space := InputEventKey.new()
	key_space.keycode = KEY_SPACE
	InputMap.action_add_event("FPS_Jump", key_space)
	
	InputMap.add_action("FPS_Forward")
	var key_w := InputEventKey.new()
	key_w.keycode = KEY_W
	InputMap.action_add_event("FPS_Forward", key_w)
	
	InputMap.add_action("FPS_Back")
	var key_s := InputEventKey.new()
	key_s.keycode = KEY_S
	InputMap.action_add_event("FPS_Back", key_s)
	
	InputMap.add_action("FPS_Left")
	var key_a := InputEventKey.new()
	key_a.keycode = KEY_A
	InputMap.action_add_event("FPS_Left", key_a)
	
	InputMap.add_action("FPS_Right")
	var key_d := InputEventKey.new()
	key_d.keycode = KEY_D
	InputMap.action_add_event("FPS_Right", key_d)
	
	InputMap.add_action("FPS_Zoom")
	var key_zoom := InputEventMouseButton.new()
	key_zoom.button_index = MOUSE_BUTTON_WHEEL_UP
	InputMap.action_add_event("FPS_Zoom", key_zoom)
	
	InputMap.add_action("FPS_Sprint")
	var key_sprint := InputEventKey.new()
	key_sprint.keycode = KEY_SHIFT
	InputMap.action_add_event("FPS_Sprint", key_sprint)
	
	InputMap.add_action("FPS_Unzoom")
	var key_unzoom := InputEventMouseButton.new()
	key_unzoom.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("FPS_Unzoom", key_unzoom)
	
	InputMap.add_action("FPS_Esc")
	var key_esc := InputEventKey.new()
	key_esc.keycode = KEY_ESCAPE
	InputMap.action_add_event("FPS_Esc", key_esc)
