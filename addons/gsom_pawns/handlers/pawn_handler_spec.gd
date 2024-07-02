extends GsomPawnHandler


## The body will try to reach this speed while running in ONE direction.
@export var max_speed: float = 7.2 # 300 unit/sec == AG standard

## Acceleration multiplier. The [code]max_speed[/code] is
## multiplied by this to get the final acceleration.
@export var accel_k: float = 12.0

## How soon whe body will stop with no input - it loses that many m/s from its speed.
@export var stop_speed: float = 2.45

## Move this much faster when sprinting
@export var sprint_multiplier: float = 2.0


func _do_physics(pawn: GsomPawn, dt: float) -> void:
	var body: Node3D = pawn.body
	
	var wish_axis := Vector3.ZERO
	var basis = pawn.get_action("basis", Basis.IDENTITY)
	
	if pawn.get_action("forward", false):
		wish_axis.z -= 1.0
	if pawn.get_action("back", false):
		wish_axis.z += 1.0
	if pawn.get_action("moveleft", false):
		wish_axis.x -= 1.0
	if pawn.get_action("moveright", false):
		wish_axis.x += 1.0
	if pawn.get_action("jump", false):
		wish_axis.y += 1.0
	if pawn.get_action("duck", false):
		wish_axis.y -= 1.0
	
	var direction := Vector3.ZERO
	var forward: Vector3 = basis.z
	var left: Vector3 = basis.x
	var up: Vector3 = basis.y
	direction = (forward * wish_axis.z + left * wish_axis.x + up * wish_axis.y).normalized()
	
	var target_speed: float = max_speed
	if pawn.get_action("sprint", false):
		target_speed *= sprint_multiplier
	
	if direction.length():
		body.linear_velocity += direction * dt * accel_k * max_speed
		if body.linear_velocity.length() > target_speed:
			body.linear_velocity = body.linear_velocity.normalized() * target_speed
	else:
		var speed: float = body.linear_velocity.length()
		var new_speed: float = max(0.0, speed - dt * max_speed * stop_speed)
		body.linear_velocity = body.linear_velocity.normalized() * new_speed
	
