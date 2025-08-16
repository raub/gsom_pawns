@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

var __pawn: GsomPawn = null
var __queue: Array[Dictionary] = []


func _ready() -> void:
	__pawn = get_parent() as GsomPawn
	if !__pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	__pawn.triggered.connect(__handle_triggers)


func __handle_triggers(trigger_name: String, value: Dictionary) -> void:
	__queue.append({ "trigger_name": trigger_name, "value": value })


func __perform_action(body: RigidBody3D, action: Dictionary) -> void:
	var trigger_name: String = action.trigger_name
	var value: Dictionary = action.value
	
	if !value.size():
		return
	
	if trigger_name == "teleport":
		body.linear_velocity = Vector3.ZERO
		body.global_position = value.pos
		__pawn.reset_envs()
	elif trigger_name == "toss":
		body.linear_velocity += value.vel
	elif trigger_name == "launch":
		body.linear_velocity.y = value.vel.y
		if abs(body.linear_velocity.x) < abs(value.vel.x):
			body.linear_velocity.x = value.vel.x
		if abs(body.linear_velocity.z) < abs(value.vel.z):
			body.linear_velocity.z = value.vel.z
	elif trigger_name == "raparent":
		pass
		#body.parent


func _do_physics(pawn: GsomPawn, _dt: float) -> void:
	if !__queue.size():
		return
	
	var body: RigidBody3D = pawn.body
	for action: Dictionary in __queue:
		__perform_action(body, action)
	
	__queue.clear()
