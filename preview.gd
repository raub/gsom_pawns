extends Node3D
class_name Main

const PATH_GDTRICKS := "res://gdtricks/gdtricks.tscn"
const PATH_GODOTA := "res://godota/godota.tscn"
const PATH_CTRL_FPS := "res://controllers/fps/controller_fps.tscn"
const PATH_CTRL_RTS := "res://controllers/rts/controller_rts.tscn"
const PATH_CHAR_HUMAN := "res://characters/human/char_human.tscn"
const PATH_CHAR_VTOL := "res://characters/vtol/char_vtol.tscn"
const PATH_CHAR_SPEC := "res://characters/spec/char_spec.tscn"

static var _instance: Main = null

var _load_queue := {}
var _char_human: Node3D = null
var _char_vtol: Node3D = null
var _char_spec: Node3D = null
var _controller_fps: Node3D = null
var _controller_rts: Node3D = null


@onready var _timer_load: Timer = $TimerLoad
@onready var _label_loading: Label = $LabelLoading

func _ready() -> void:
	_instance = self
	
	_timer_load.connect("timeout", _update_load)
	
	_load_async(PATH_CTRL_FPS, _on_load_cases)
	_load_async(PATH_GDTRICKS, _on_load_cases)
	_load_async(PATH_CTRL_RTS, _on_load_cases)


static func _nop(_res: PackedScene, _path: String) -> void:
	pass

static func load_async(path: String, cb: Callable = Main._nop) -> void:
	_instance._load_async(path, cb)


func _on_load_cases(res: PackedScene, path: String) -> void:
	var inst: Node = res.instantiate()
	
	# Need to set position before "ready"
	if path == PATH_CHAR_HUMAN:
		inst.position = Vector3(0.0, 0.0, 5.8)
	elif path == PATH_CHAR_VTOL:
		inst.position = Vector3(-9.0, 0.0, 5.8)
	elif path == PATH_CHAR_SPEC:
		inst.position = Vector3(10.0, 7.0, 5.8)
	
	add_child(inst)
	
	if path == PATH_CTRL_RTS:
		_controller_rts = inst
		_controller_rts.switched_controller.connect(_switch_controller)
	
	if path == PATH_GDTRICKS:
		_load_async(PATH_GODOTA, _on_load_cases)
	
	if path == PATH_CTRL_FPS:
		_controller_fps = inst
		_controller_fps.kind = "human"
		_controller_fps.switched_character.connect(_switch_pawn)
		_controller_fps.switched_controller.connect(_switch_controller)
		_controller_fps.is_focused = true
		
		_load_async(PATH_CHAR_HUMAN, _on_load_cases)
		_load_async(PATH_CHAR_VTOL, _on_load_cases)
		_load_async(PATH_CHAR_SPEC, _on_load_cases)
	
	if path == PATH_CHAR_HUMAN:
		_char_human = inst
		_controller_fps.possess(_char_human.pawn)
	
	if path == PATH_CHAR_VTOL:
		_char_vtol = inst
		
	if path == PATH_CHAR_SPEC:
		_char_spec = inst


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


func _load_async(path: String, cb: Callable = _nop) -> void:
	if !_load_queue.has(path):
		ResourceLoader.load_threaded_request(path)
		_load_queue[path] = cb


func _update_load() -> void:
	if _label_loading.visible != (_load_queue.size() > 0):
		_label_loading.visible = _load_queue.size() > 0
	
	for path: String in _load_queue:
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		
		var cb: Callable = _load_queue[path]
		_load_queue.erase(path)
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(path) as PackedScene
			if cb == Main._nop:
				var inst: Node = res.instantiate()
				add_child(inst)
			else:
				cb.call(res, path)
