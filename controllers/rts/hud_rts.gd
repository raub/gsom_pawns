extends Control

signal panned(dxy: Vector2)

@onready var _scroll_left: Control = $ScrollLeft
@onready var _scroll_right: Control = $ScrollRight
@onready var _scroll_up: Control = $ScrollUp
@onready var _scroll_down: Control = $ScrollDown
@onready var _control: Control = $HBoxContainer/RectMap/TextureRect/Control
@onready var _rect_map: Control = $HBoxContainer/RectMap

var _wish_scroll := Vector2.ZERO
@export var wish_scroll: Vector2 = _wish_scroll:
	get:
		return _wish_scroll


func _ready() -> void:
	_scroll_left.mouse_entered.connect(func () -> void: _wish_scroll.x = -1.0)
	_scroll_right.mouse_entered.connect(func () -> void: _wish_scroll.x = 1.0)
	_scroll_up.mouse_entered.connect(func () -> void: _wish_scroll.y = -1.0)
	_scroll_down.mouse_entered.connect(func () -> void: _wish_scroll.y = 1.0)
	
	_scroll_left.mouse_exited.connect(func () -> void: _wish_scroll.x = 0.0)
	_scroll_right.mouse_exited.connect(func () -> void: _wish_scroll.x = 0.0)
	_scroll_up.mouse_exited.connect(func () -> void: _wish_scroll.y = 0.0)
	_scroll_down.mouse_exited.connect(func () -> void: _wish_scroll.y = 0.0)


func move_map_screen(percent: Vector2) -> void:
	_control.position = _rect_map.size * percent


func _process(_dt: float) -> void:
	if !visible:
		_wish_scroll = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if !(event is InputEventMouseMotion):
		return
	
	var event_motion := event as InputEventMouseMotion
	if Input.is_action_pressed("RTS_Pan"):
		panned.emit(event_motion.relative)
		accept_event()
