@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

## Physics-based RigidBody3D zero-g handler.
##
## It is similar to [code]handler_rigid_walk[/code], but:
## - is always "in air"
## - has 3D airmove


## The body will try to reach this speed while running in ONE direction.
@export var max_speed_run: float = 7.2 # 300 unit/sec == AG standard

## The body will try to reach this speed while flying in ONE direction.
@export var max_speed_fly: float = 0.73 # 30 unit/sec

## Acceleration multiplier for running.
@export var accel_fly_k: float = 12.0


func _do_integrate(pawn: GsomPawn, state: PhysicsDirectBodyState3D) -> void:
	var body: RigidBody3D = pawn.body
	
	var dt: float = state.step
	var direction := Vector3.ZERO
	var basis: Basis = pawn.get_action("basis", Basis.IDENTITY)
	
	var wish_axis := Vector3.ZERO
	if pawn.get_action("forward", false):
		wish_axis.z += 1.0
	if pawn.get_action("back", false):
		wish_axis.z -= 1.0
	if pawn.get_action("moveleft", false):
		wish_axis.x -= 1.0
	if pawn.get_action("moveright", false):
		wish_axis.x += 1.0
	if pawn.get_action("jump", false):
		wish_axis.y += 1.0
	if pawn.get_action("duck", false):
		wish_axis.y -= 1.0
	
	if abs(wish_axis.x) + abs(wish_axis.y) + abs(wish_axis.z) > 0.1:
		var forward: Vector3 = -basis.z
		var left: Vector3 = basis.x
		var up: Vector3 = basis.y
		direction = (forward * wish_axis.z + left * wish_axis.x + up * wish_axis.y).normalized()
	
	var accel_fly: float = accel_fly_k * max_speed_run
	
	if direction.length():
		var curspeed: float = body.linear_velocity.dot(direction)
		var addspeed: float = clampf(max_speed_fly - curspeed, 0, accel_fly * dt)
		body.linear_velocity += direction * addspeed
