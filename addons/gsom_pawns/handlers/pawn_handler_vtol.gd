extends GsomPawnHandler


## The body will try to reach this speed while running in ONE direction.
@export var max_speed: float = 7.2 # 300 unit/sec == AG standard

## Acceleration multiplier. The [code]max_speed[/code] is
## multiplied by this to get the final acceleration.
@export var accel_k: float = 6.0

## Move this much faster when sprinting
@export var sprint_multiplier: float = 2.0

## Decrease the Y component of velocity by this much every second.
##
## Somehow it's not "9.8", just feels better this way. By default Half-Life 1 has
## "sv_gravity 800" ~ 19.5 m/s2, so not far off.
@export var accel_gravity: float = 18.0


func _do_integrate(pawn: GsomPawn, state: PhysicsDirectBodyState3D) -> void:
	var body: RigidBody3D = pawn.body
	
	var dt: float = state.step
	var wish_axis := Vector2.ZERO
	var basis = body.basis
	
	if pawn.get_action("forward", false):
		wish_axis.x -= 1.0
	if pawn.get_action("back", false):
		wish_axis.x += 1.0
	if pawn.get_action("moveleft", false):
		wish_axis.y += 1.0
	if pawn.get_action("moveright", false):
		wish_axis.y -= 1.0
	
	body.angular_velocity *= 0.98
	body.angular_velocity.x += wish_axis.x * 0.03
	body.angular_velocity.z += wish_axis.y * 0.03
	body.angular_velocity.y = 0
	
	var thrust: float = 0.0
	if pawn.get_action("jump", false):
		thrust += 1.0
	if pawn.get_action("duck", false):
		thrust -= 0.5
		
	body.linear_velocity *= 0.98
	if !pawn.get_action("sprint", false):
		body.linear_velocity.y += thrust * dt * accel_k * max_speed
	elif thrust > 0:
		body.linear_velocity.z -= thrust * dt * accel_k * max_speed
	#else:
	
