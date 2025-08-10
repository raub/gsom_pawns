extends Control
class_name HudRts

signal panned(dxy: Vector2)
signal pressed_map(xy_t: Vector2)

const __XY_T_MIN := Vector2(0.01, 0.01)
const __XY_T_MAX := Vector2(0.99, 0.99)
const __SCROLL_MARGIN: float = 16.0 # px
const __MAP_INPUT_BUTTONS: int = (
	MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE
)

var __wish_scroll := Vector2.ZERO
@export var wish_scroll: Vector2 = __wish_scroll:
	get:
		return __wish_scroll

@onready var __control: Control = $HBoxContainer/RectMap/TextureRect/Control
@onready var __rect_map: Control = $HBoxContainer/RectMap
@onready var __selection_rect: Control = $SelectionRect
@onready var __rect_map_texture: Control = $HBoxContainer/RectMap/TextureRect


func _ready() -> void:
	__rect_map_texture.gui_input.connect(__handle_map_input)


func set_selection(start: Vector2, end: Vector2) -> void:
	__selection_rect.position = Vector2(minf(start.x, end.x), minf(start.y, end.y))
	__selection_rect.size = Vector2(absf(start.x - end.x), absf(start.y - end.y))


func __handle_map_input(event: InputEvent) -> void:
	var event_mouse := event as InputEventMouse
	if !event_mouse or (event_mouse.button_mask & __MAP_INPUT_BUTTONS == 0):
		return
	
	__wish_scroll = Vector2.ZERO
	var xy_t: Vector2 = event_mouse.position / __rect_map_texture.size
	xy_t.x = clampf(xy_t.x, __XY_T_MIN.x, __XY_T_MAX.x)
	xy_t.y = clampf(xy_t.y, __XY_T_MIN.y, __XY_T_MAX.y)
	pressed_map.emit(xy_t)
	accept_event()


func move_map_screen(percent: Vector2) -> void:
	__control.position = __rect_map.size * percent


func _process(_dt: float) -> void:
	if !visible:
		__wish_scroll = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var event_motion := event as InputEventMouseMotion
	if !event_motion:
		return
	
	if Input.is_action_pressed("RTS_Pan"):
		panned.emit(event_motion.relative)
		__wish_scroll = Vector2.ZERO
		accept_event()
		return
	
	var xy: Vector2 = event_motion.position
	var sz: Vector2 = size
	
	if xy.x < __SCROLL_MARGIN:
		__wish_scroll.x = -1.0
	elif xy.x > sz.x - __SCROLL_MARGIN:
		__wish_scroll.x = 1.0
	else:
		__wish_scroll.x = 0.0
	
	if xy.y < __SCROLL_MARGIN:
		__wish_scroll.y = -1.0
	elif xy.y > sz.y - __SCROLL_MARGIN:
		__wish_scroll.y = 1.0
	else:
		__wish_scroll.y = 0.0
	
	if __wish_scroll.length_squared() > 0.01:
		accept_event()
