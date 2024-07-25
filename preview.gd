extends Node3D
class_name Main

const _PATH_GDTRICKS := "res://maps/gdtricks/gdtricks.tscn"
const _PATH_GODOTA := "res://maps/godota/godota.tscn"
const _PATH_TEST_CHAMBER := "res://maps/test_chamber/test_chamber.tscn"
const _PATH_CTRL_FPS := "res://controllers/fps/controller_fps.tscn"
const _PATH_CTRL_RTS := "res://controllers/rts/controller_rts.tscn"
const _PATH_CHAR_HUMAN := "res://characters/human/char_human.tscn"
const _PATH_CHAR_VTOL := "res://characters/vtol/char_vtol.tscn"
const _PATH_CHAR_SPEC := "res://characters/spec/char_spec.tscn"

var _DISPLAY_MONITORS: PackedStringArray = [
	"TIME_FPS","TIME_PROCESS","TIME_PHYSICS_PROCESS",
	"OBJECT_COUNT","OBJECT_RESOURCE_COUNT",
	"RENDER_TOTAL_OBJECTS_IN_FRAME","RENDER_TOTAL_PRIMITIVES_IN_FRAME",
	"RENDER_TOTAL_DRAW_CALLS_IN_FRAME",
]

static var _instance: Main = null

var _load_queue := {}
var _char_human: Node3D = null
var _char_vtol: Node3D = null
var _char_spec: Node3D = null
var _controller_fps: Node3D = null
var _controller_rts: Node3D = null


@onready var _timer_load: Timer = $TimerLoad
@onready var _timer_perf: Timer = $TimerPerf
@onready var _label_loading: Label = $LabelLoading
@onready var _label_perf: Label = $LabelPerf
@onready var _container: Node = $Container


func _ready() -> void:
	_instance = self
	
	_timer_load.connect("timeout", _update_load)
	_timer_perf.connect("timeout", _update_perf)
	
	_load_async(_PATH_CTRL_FPS, _on_load_cases)
	_load_async(_PATH_GDTRICKS, _on_load_cases)
	_load_async(_PATH_CTRL_RTS, _on_load_cases)


static func _nop(_res: PackedScene, _path: String) -> void:
	pass


static func load_async(path: String, cb: Callable = Main._nop) -> void:
	_instance._load_async(path, cb)


func _on_load_cases(res: PackedScene, path: String) -> void:
	var inst: Node = res.instantiate()
	
	# Need to set position before "ready"
	if path == _PATH_CHAR_HUMAN:
		inst.position = Vector3(0.0, 0.0, 5.8)
	elif path == _PATH_CHAR_VTOL:
		inst.position = Vector3(-9.0, 0.0, 5.8)
	elif path == _PATH_CHAR_SPEC:
		inst.position = Vector3(10.0, 7.0, 5.8)
	
	_container.add_child(inst)
	
	if path == _PATH_CTRL_RTS:
		_controller_rts = inst
		_controller_rts.switched_controller.connect(_switch_controller)
	
	if path == _PATH_GDTRICKS:
		_load_async(_PATH_GODOTA, _on_load_cases)
		_load_async(_PATH_TEST_CHAMBER, _on_load_cases)
	
	if path == _PATH_CTRL_FPS:
		_controller_fps = inst
		_controller_fps.kind = "human"
		_controller_fps.switched_character.connect(_switch_pawn)
		_controller_fps.switched_controller.connect(_switch_controller)
		_controller_fps.is_focused = true
		
		_load_async(_PATH_CHAR_HUMAN, _on_load_cases)
		_load_async(_PATH_CHAR_VTOL, _on_load_cases)
		_load_async(_PATH_CHAR_SPEC, _on_load_cases)
	
	if path == _PATH_CHAR_HUMAN:
		_char_human = inst
		_controller_fps.possess(_char_human.pawn)
	
	if path == _PATH_CHAR_VTOL:
		_char_vtol = inst
		
	if path == _PATH_CHAR_SPEC:
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
				_container.add_child(inst)
			else:
				cb.call(res, path)


func get_perf_line(perf_name: String) -> String:
	return ("%s: %s" % [perf_name, Performance.get_monitor(Performance[perf_name])])


func _update_perf() -> void:
	if !_label_perf.visible:
		return
	
	var text: String = ""
	for perf_name: String in _DISPLAY_MONITORS:
		text += get_perf_line(perf_name) + "\n"
	
	_label_perf.text = text
