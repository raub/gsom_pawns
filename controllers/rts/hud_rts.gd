extends Control

signal panned(dxy: Vector2)

@onready var _scroll_left: Control = $ScrollLeft
@onready var _scroll_right: Control = $ScrollRight
@onready var _scroll_up: Control = $ScrollUp
@onready var _scroll_down: Control = $ScrollDown
@onready var _control: Control = $HBoxContainer/RectMap/TextureRect/Control
@onready var _rect_map: Control = $HBoxContainer/RectMap
@onready var _selection_rect: Control = $SelectionRect
@onready var _rect_map_texture: Control = $HBoxContainer/RectMap/TextureRect


var _wish_scroll := Vector2.ZERO
@export var wish_scroll: Vector2 = _wish_scroll:
	get:
		return _wish_scroll


func set_selection(start: Vector2, end: Vector2) -> void:
	_selection_rect.position = Vector2(min(start.x, end.x), min(start.y, end.y))
	_selection_rect.size = Vector2(abs(start.x - end.x), abs(start.y - end.y))


func _ready() -> void:
	_scroll_left.mouse_entered.connect(func () -> void: _wish_scroll.x = -1.0)
	_scroll_right.mouse_entered.connect(func () -> void: _wish_scroll.x = 1.0)
	_scroll_up.mouse_entered.connect(func () -> void: _wish_scroll.y = -1.0)
	_scroll_down.mouse_entered.connect(func () -> void: _wish_scroll.y = 1.0)
	
	_scroll_left.mouse_exited.connect(func () -> void: _wish_scroll.x = 0.0)
	_scroll_right.mouse_exited.connect(func () -> void: _wish_scroll.x = 0.0)
	_scroll_up.mouse_exited.connect(func () -> void: _wish_scroll.y = 0.0)
	_scroll_down.mouse_exited.connect(func () -> void: _wish_scroll.y = 0.0)
	
	_rect_map_texture.gui_input.connect(_handle_map_input)


func _handle_map_input(event: InputEvent) -> void:
	pass


func move_map_screen(percent: Vector2) -> void:
	_control.position = _rect_map.size * percent


func _process(_dt: float) -> void:
	if !visible:
		_wish_scroll = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("RTS_Pan"):
		var event_motion := event as InputEventMouseMotion
		if event_motion:
			panned.emit(event_motion.relative)
		accept_event()
