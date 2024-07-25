@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

## Water volume swimming handler for rigid body pawns.

## Swim sideways and forward this fast.
@export var swim_speed: float = 3.0

## Idle swim stopping speed.
@export var stop_speed: float = 2.0

## Swim acceleration.
@export var accel_swim: float = 10.0

## Sink acceleration while idle.
@export var accel_gravity: float = 15.0

## Maximum idle sinking speed.
@export var sink_speed: float = 1.0


func _do_integrate(pawn: GsomPawn, state: PhysicsDirectBodyState3D) -> void:
	var body: RigidBody3D = pawn.body
	
	var dt: float = state.step
	var basis: Basis = pawn.get_action("basis", Basis.IDENTITY)
	
	var wish_axis := Vector3.ZERO
	if pawn.get_action("forward", false):
		wish_axis.z -= 1.0
	if pawn.get_action("back", false):
		wish_axis.z += 1.0
	if pawn.get_action("moveleft", false):
		wish_axis.x -= 1.0
	if pawn.get_action("moveright", false):
		wish_axis.x += 1.0
	
	var is_jump: bool = pawn.get_action("jump", false)
	
	if abs(wish_axis.z) > 0.1 or abs(wish_axis.x) > 0.1 or is_jump:
		var forward: Vector3 = basis.z
		var left: Vector3 = basis.x
		var up: Vector3 = Vector3.UP * (1.0 if is_jump else 0.0)
		var direction: Vector3 = (forward * wish_axis.z + left * wish_axis.x + up).normalized()
		body.linear_velocity += direction * dt * accel_swim * swim_speed
		if body.linear_velocity.length() > swim_speed:
			body.linear_velocity = body.linear_velocity.normalized() * swim_speed
	else:
		var dv: Vector3 = body.linear_velocity.normalized() * dt * accel_swim * stop_speed
		if dv.length_squared() > body.linear_velocity.length_squared():
			body.linear_velocity = Vector3.ZERO
		else:
			body.linear_velocity -= dv
		
		var new_vy: float = maxf(-sink_speed, body.linear_velocity.y - accel_gravity * dt)
		body.linear_velocity.y = new_vy
