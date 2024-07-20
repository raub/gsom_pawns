@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

var _pawn: GsomPawn = null
var _queue: Array[Dictionary] = []


func _ready() -> void:
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_pawn.triggered.connect(_handle_triggers)


func _handle_triggers(trigger_name: String, value: Dictionary) -> void:
	_queue.append({ "trigger_name": trigger_name, "value": value })


func _perform_action(body: RigidBody3D, action: Dictionary) -> void:
	var trigger_name: String = action.trigger_name
	var value: Variant = action.value
	
	if trigger_name == "teleport":
		body.linear_velocity = Vector3.ZERO
		body.global_position = value.pos
		_pawn.reset_envs()
	elif trigger_name == "toss":
		body.linear_velocity += value.vel
	elif trigger_name == "launch":
		body.linear_velocity = value.vel


func _do_physics(pawn: GsomPawn, _dt: float) -> void:
	if !_queue.size():
		return
	
	var body: RigidBody3D = pawn.body
	for action: Dictionary in _queue:
		_perform_action(body, action)
	
	_queue.clear()
