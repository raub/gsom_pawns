extends GsomPawnHandler


## The body will try to reach this speed while running in ONE direction.
@export var max_speed: float = 7.2 # 300 unit/sec == AG standard

## Acceleration multiplier. The [code]max_speed[/code] is
## multiplied by this to get the final acceleration.
@export var accel_k: float = 3.0

## Decrease the Y component of velocity by this much every second.
##
## Somehow it's not "9.8", just feels better this way. By default Half-Life 1 has
## "sv_gravity 800" ~ 19.5 m/s2, so not far off.
@export var accel_gravity: float = 18.0


func _do_integrate(pawn: GsomPawn, state: PhysicsDirectBodyState3D) -> void:
	var body: RigidBody3D = pawn.body
	
	var dt: float = state.step
	var wish_axis := Vector2.ZERO
	
	if pawn.has_action("basis"):
		var basis: Basis = pawn.get_action("basis", Basis.IDENTITY)
		body.basis = body.basis.slerp(basis.orthonormalized(), dt)
	
	var thrust: float = 0.0
	if pawn.get_action("jump", false) or pawn.get_action("forward", false):
		thrust += 1.0
	if pawn.get_action("duck", false) or pawn.get_action("back", false):
		thrust -= 0.5
	
	if pawn.get_action("sprint", false) or pawn.get_action("forward", false):
		body.linear_velocity *= 0.998
		var hvel := Vector2(body.linear_velocity.x, body.linear_velocity.z)
		body.linear_velocity.y -= (accel_gravity * dt) / max(1.0, hvel.length() * 0.3)
		if thrust > 0:
			body.linear_velocity -= body.basis.z * dt * thrust * accel_k * max_speed
	else:
		body.linear_velocity *= 0.99
		body.linear_velocity.y -= accel_gravity * dt
		body.linear_velocity += body.basis.y * dt * (thrust * accel_k * max_speed + accel_gravity)
	
