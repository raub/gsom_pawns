@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

## Physics-based RigidBody3D pawn handler.
##
## It is based on Half-Life 1 movement, and the defaults reflect that.
## The unit conversion is inferred from:
## [url]https://twhl.info/wiki/page/Tutorial%3A_Dimensions[url].
## Roughly: 1 unit ~ 0.024 m 1 m ~ 41 unit.
## [br]
## The acceleration code is similar to Quake 1 which can be found here:
## [url]https://github.com/id-Software/Quake/blob/master/WinQuake/sv_user.c#L190[url].
## [br]
## The Pawn node is designed for Actors that can be controlled by players or AI.
## A Pawn is the physical representation of a player or AI entity within the world.
## The Pawn determines how it interacts with the world in terms of collisions
## and other physical interactions.
## Some types of games may not have a visible player mesh or avatar within the game.
## Regardless, the Pawn still represents the physical location, rotation, etc. of
## a player or entity within the game.
## You will need a Controller to possess a Pawn and generate input signals for it.


## The body will try to reach this speed while running in ONE direction.
##
## This also impacts indirectly all acceleration-related behaviors - as per
## Quake 1 / Half-Life 1 physics reference. The default value 7.2 is similar to
## 300 units which is AG standard. Other values are:
## 6.48 m/s ~ 270 unit/s, 7.8 m/s ~ 320 unit/s.
@export var max_speed_run: float = 7.2 # 300 unit/sec == AG standard

## The body will try to reach this speed while flying in ONE direction. Meaning
## if you start falling from speed 0, and then hold W,
## the top forward speed should reach this value.
##
## However, the air-acceleration will depend on [code]max_speed_run[/code] value.
## This is acheived by changing the direction - as per Quake 1 / Half-Life 1
## physics reference. The most obvious use-case is acceleration during BHOP.
@export var max_speed_fly: float = 0.73 # 30 unit/sec

## Acceleration multiplier for running. The [code]max_speed_run[/code] is
## multiplied by this to get the final acceleration.
@export var accel_run_k: float = 12.0

## Acceleration multiplier for running. The [code]max_speed_run[/code]
## (and not [code]max_speed_fly[/code]!) is
## multiplied by this to get the final acceleration.
@export var accel_fly_k: float = 12.0

## This speed is directly assigned to the body when it performs a jump.
@export var speed_jump: float = 6.2 # validate per 44 (and 62) unit - 1.07 m (and 1.5 m)

## Decrease the Y component of velocity by this much every second.
##
## Somehow it's not "9.8", just feels better this way. By default Half-Life 1 has
## "sv_gravity 800" ~ 19.5 m/s2.
@export var accel_gravity: float = 19.5

## How soon whe body will stop with no input - it loses that many m/s from its speed.
@export var stop_speed: float = 2.45 # ~100 unit/sec

## Move this much slower when crouching
@export var duck_multiplier: float = 0.333333


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
		wish_axis.x += 1.0
	if pawn.get_action("moveright", false):
		wish_axis.x -= 1.0
	
	var is_jump: bool = pawn.get_action("jump", false)
	var is_duck: bool = pawn.get_state("duck", false)
	var is_ground: bool = pawn.get_state("on_ground", false)
	var normal: Vector3 = pawn.get_state("normal", Vector3.UP)
	
	if abs(wish_axis.z) > 0.1 or abs(wish_axis.x) > 0.1:
		var forward: Vector3 = body.normal.cross(basis.x)
		var left: Vector3 = body.normal.cross(-basis.z)
		direction = (forward * wish_axis.z + left * wish_axis.x).normalized()
	
	var accel_fly: float = accel_fly_k * max_speed_run
	
	if is_ground:
		if is_jump:
			body.linear_velocity.y = maxf(body.linear_velocity.y, speed_jump)
			if direction.length():
				var curspeed: float = body.linear_velocity.dot(direction)
				var addspeed: float = clampf(max_speed_fly - curspeed, 0, accel_fly * dt)
				body.linear_velocity += direction * addspeed
		else:
			var curspeed1: float = body.linear_velocity.length()
			var control: float = stop_speed if curspeed1 < stop_speed else curspeed1
			var newspeed: float = clampf(curspeed1 - 4.0 * control * dt, 0.0, curspeed1)
			var fract: float = newspeed / curspeed1 if curspeed1 else 0.0
			
			body.linear_velocity *= fract
			if direction.length():
				var wishspeed: float = max_speed_run
				if is_duck:
					wishspeed *= duck_multiplier
				var curspeed: float = body.linear_velocity.dot(direction)
				var accel_run: float = accel_run_k * max_speed_run
				var addspeed: float = clampf(wishspeed - curspeed, 0, accel_run * dt)
				body.linear_velocity += direction * addspeed
	else:
		body.linear_velocity.y -= accel_gravity * dt
		if direction.length():
			var curspeed: float = body.linear_velocity.dot(direction)
			var addspeed: float = clampf(max_speed_fly - curspeed, 0, accel_fly * dt)
			body.linear_velocity += direction * addspeed
