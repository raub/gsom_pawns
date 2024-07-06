extends Node3D

@onready var _char_human: Node3D = $CharHuman
@onready var _char_vtol: Node3D = $CharVtol
@onready var _char_spec: Node3D = $CharSpec
@onready var _controller_fps: Node3D = $ControllerFps
@onready var _controller_rts: Node3D = $ControllerRts


func _ready() -> void:
	_controller_fps.kind = "human"
	_controller_fps.possess(_char_human.pawn)
	_controller_fps.switched_character.connect(_switch_pawn)
	_controller_fps.switched_controller.connect(_switch_controller)
	
	_controller_rts.switched_controller.connect(_switch_controller)


func _switch_pawn(char_kind: String) -> void:
	_controller_fps.kind = char_kind
	if char_kind == "vtol":
		_controller_fps.possess(_char_vtol.pawn)
	elif char_kind == "human":
		_controller_fps.possess(_char_human.pawn)
	else:
		_controller_fps.possess(_char_spec.pawn)


func _switch_controller(ctrl_kind: String) -> void:
	_controller_fps.is_focused = ctrl_kind == "fps"
	_controller_rts.is_focused = ctrl_kind == "rts"
