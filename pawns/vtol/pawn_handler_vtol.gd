extends GsomPawnHandler


## Acceleration multiplier. The [code]max_speed[/code] is
## multiplied by this to get the final acceleration.
@export var accel_k: float = 20.0

## Decrease the Y component of velocity by this much every second.
@export var accel_gravity: float = 19.5


func _do_integrate(pawn: GsomPawn, state: PhysicsDirectBodyState3D) -> void:
	var body: RigidBody3D = pawn.body
	var dt: float = state.step
	
	var is_ground: bool = pawn.get_state("on_ground", false)
	var is_forward: bool = pawn.get_action("sprint", false) or pawn.get_action("forward", false)
	var is_power_up: bool = pawn.get_action("jump", false) or pawn.get_action("forward", false)
	var is_power_down: bool = pawn.get_action("duck", false) or pawn.get_action("back", false)
	
	if pawn.has_action("basis") and not is_ground:
		var view_basis: Basis = pawn.get_action("basis", Basis.IDENTITY)
		
		if is_forward:
			body.basis = body.basis.slerp(Basis.looking_at(-view_basis.z, Vector3.UP), dt)
		else:
			var forward: Vector3 = Vector3.UP.cross(view_basis.x)
			body.basis = body.basis.slerp(Basis.looking_at(forward, Vector3.UP), dt)
	else:
		var forward: Vector3 = Vector3.UP.cross(body.basis.x)
		body.basis = Basis.looking_at(forward, Vector3.UP)
	
	var thrust: float = 0.0
	if is_power_up:
		thrust += 1.0
	if is_power_down:
		thrust -= 0.5
	
	body.linear_velocity.y -= accel_gravity * dt
	
	if is_forward:
		if not is_ground:
			var hvel := Vector2(body.linear_velocity.x, body.linear_velocity.z)
			body.linear_velocity.y += dt * sqrt(hvel.length()) * 0.2 * accel_gravity
			body.linear_velocity *= 0.998
			if thrust > 0:
				body.linear_velocity -= body.basis.z * dt * thrust * accel_k
		else:
			body.linear_velocity *= 0.9
	else:
		body.linear_velocity += body.basis.y * dt * (thrust * accel_k + accel_gravity)
		body.linear_velocity *= 0.9 if (is_ground and thrust < 0.1) else 0.99
	
