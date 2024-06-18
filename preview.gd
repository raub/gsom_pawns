extends Node3D

@onready var pawn_human = $PawnHuman
@onready var controller = $Controller


func _ready() -> void:
	_register_actions()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	controller.possess(pawn_human)


#func _process(_dt: float) -> void:
	#if Input.is_action_just_pressed("Esc"):
		#get_tree().quit()


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
	
	InputMap.add_action("Unzoom")
	var keyUnzoom := InputEventMouseButton.new()
	keyUnzoom.button_index = MOUSE_BUTTON_WHEEL_DOWN
	InputMap.action_add_event("Unzoom", keyUnzoom)
	
	InputMap.add_action("Esc")
	var keyEsc := InputEventKey.new()
	keyEsc.keycode = KEY_ESCAPE
	InputMap.action_add_event("Esc", keyEsc)
