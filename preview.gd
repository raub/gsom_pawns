extends Node3D

@onready var _char_human: Node3D = $CharHuman2
@onready var _char_vtol: Node3D = $CharVtol
@onready var _char_spec: Node3D = $CharSpec
@onready var _controller: Node3D = $Controller


func _ready() -> void:
	_register_actions()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_controller.possess(_char_human.pawn)
	_controller.switched.connect(_switch_pawn)


func _switch_pawn(kind: String) -> void:
	if kind == "vtol":
		_controller.possess(_char_vtol.pawn)
	elif kind == "human":
		_controller.possess(_char_human.pawn)
	else:
		_controller.possess(_char_spec.pawn)


func _register_actions() -> void:
	InputMap.add_action("Duck")
	var keyCtrl := InputEventKey.new()
	keyCtrl.keycode = KEY_CTRL
	InputMap.action_add_event("Duck", keyCtrl)
	
	InputMap.add_action("Jump")
	var keySpace := InputEventKey.new()
	keySpace.keycode = KEY_SPACE
	InputMap.action_add_event("Jump", keySpace)
	
	InputMap.add_action("Forward")
	var keyW := InputEventKey.new()
	keyW.keycode = KEY_W
	InputMap.action_add_event("Forward", keyW)
	
	InputMap.add_action("Back")
	var keyS := InputEventKey.new()
	keyS.keycode = KEY_S
	InputMap.action_add_event("Back", keyS)
	
	InputMap.add_action("Left")
	var keyA := InputEventKey.new()
	keyA.keycode = KEY_A
	InputMap.action_add_event("Left", keyA)
	
	InputMap.add_action("Right")
	var keyD := InputEventKey.new()
	keyD.keycode = KEY_D
	InputMap.action_add_event("Right", keyD)
	
	InputMap.add_action("Zoom")
	var keyZoom := InputEventMouseButton.new()
	keyZoom.button_index = MOUSE_BUTTON_WHEEL_UP
	InputMap.action_add_event("Zoom", keyZoom)
	
	InputMap.add_action("Sprint")
	var keySprint := InputEventKey.new()
	keySprint.keycode = KEY_SHIFT
	InputMap.action_add_event("Sprint", keySprint)
	
	InputMap.add_action("Unzoom")
	var keyUnzoom := InputEventMouseButton.new()
	keyUnzoom.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("Unzoom", keyUnzoom)
	
	InputMap.add_action("Esc")
	var keyEsc := InputEventKey.new()
	keyEsc.keycode = KEY_ESCAPE
	InputMap.action_add_event("Esc", keyEsc)
