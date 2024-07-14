extends Control

signal panned(dxy: Vector2)
signal pressed_map(xy_t: Vector2)

const _XY_T_MIN := Vector2(0.01, 0.01)
const _XY_T_MAX := Vector2(0.99, 0.99)
const _SCROLL_MARGIN: float = 16.0 # px
const _MAP_INPUT_BUTTONS: int = (
	MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE
)

var _wish_scroll := Vector2.ZERO
@export var wish_scroll: Vector2 = _wish_scroll:
	get:
		return _wish_scroll

@onready var _control: Control = $HBoxContainer/RectMap/TextureRect/Control
@onready var _rect_map: Control = $HBoxContainer/RectMap
@onready var _selection_rect: Control = $SelectionRect
@onready var _rect_map_texture: Control = $HBoxContainer/RectMap/TextureRect


func _ready() -> void:
	_rect_map_texture.gui_input.connect(_handle_map_input)


func set_selection(start: Vector2, end: Vector2) -> void:
	_selection_rect.position = Vector2(min(start.x, end.x), min(start.y, end.y))
	_selection_rect.size = Vector2(abs(start.x - end.x), abs(start.y - end.y))


func _handle_map_input(event: InputEvent) -> void:
	var event_mouse := event as InputEventMouse
	if !event_mouse or (event_mouse.button_mask & _MAP_INPUT_BUTTONS == 0):
		return
	
	_wish_scroll = Vector2.ZERO
	var xy_t: Vector2 = event_mouse.position / _rect_map_texture.size
	xy_t.x = clamp(xy_t.x, _XY_T_MIN.x, _XY_T_MAX.x)
	xy_t.y = clamp(xy_t.y, _XY_T_MIN.y, _XY_T_MAX.y)
	pressed_map.emit(xy_t)
	accept_event()


func move_map_screen(percent: Vector2) -> void:
	_control.position = _rect_map.size * percent


func _process(_dt: float) -> void:
	if !visible:
		_wish_scroll = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	var event_motion := event as InputEventMouseMotion
	if !event_motion:
		return
	
	if Input.is_action_pressed("RTS_Pan"):
		panned.emit(event_motion.relative)
		_wish_scroll = Vector2.ZERO
		accept_event()
		return
	
	var xy: Vector2 = event_motion.position
	var sz: Vector2 = size
	
	if xy.x < _SCROLL_MARGIN:
		_wish_scroll.x = -1.0
	elif xy.x > sz.x - _SCROLL_MARGIN:
		_wish_scroll.x = 1.0
	else:
		_wish_scroll.x = 0.0
	
	if xy.y < _SCROLL_MARGIN:
		_wish_scroll.y = -1.0
	elif xy.y > sz.y - _SCROLL_MARGIN:
		_wish_scroll.y = 1.0
	else:
		_wish_scroll.y = 0.0
	
	if _wish_scroll.length_squared() > 0.01:
		accept_event()
