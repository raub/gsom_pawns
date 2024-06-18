extends Node3D

var _loadQueue: PackedStringArray = []

@onready var _timer_load: Timer = $TimerLoad


func _ready() -> void:
	_timer_load.connect("timeout", _updateLoad)
	
	_loadAsync("res://gdtricks/scenes/gdtricks-agtricks-1.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-agtricks-2.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-agtricks-3.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-agtricks-4.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-agtricks-5.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-1.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-2.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-3.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-4.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-5.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-6.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-7.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-8.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-9.tscn")
	_loadAsync("res://gdtricks/scenes/gdtricks-destructo-10.tscn")


func _loadAsync(path: String):
	if !_loadQueue.has(path):
		ResourceLoader.load_threaded_request(path)
		_loadQueue.append(path)


func _updateLoad() -> void:
	for path: String in _loadQueue:
		var status = ResourceLoader.load_threaded_get_status(path)
		
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		
		_loadQueue.remove_at(_loadQueue.find(path))
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(path) as PackedScene
			var inst: Node = res.instantiate()
			add_child(inst)
