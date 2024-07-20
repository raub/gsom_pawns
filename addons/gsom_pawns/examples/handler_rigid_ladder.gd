@icon("../handlers/pawn_handler.svg")
extends GsomPawnHandler

## Ladder climbing handler for rigid body pawn.

## Go up or down with this speed.
@export var climb_speed: float = 4.0

## Go sideways with this speed (including while "jump").
@export var strafe_speed: float = 3.0

## Fall acceleration while holding "jump".
@export var accel_gravity: float = 15.0

## Only with this env active, do the ladder logic.
@export var env_name: String = "on_ladder"


func _do_integrate(pawn: GsomPawn, state: PhysicsDirectBodyState3D) -> void:
	var is_ladder: bool = pawn.has_env(env_name)
	if !is_ladder:
		return
	
	var body: RigidBody3D = pawn.body
	
	var dt: float = state.step
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
	
	var is_ground: bool = pawn.get_state("on_ground", false)
	var is_jump: bool = pawn.get_action("jump", false)
	body.linear_velocity.x = 0.0
	body.linear_velocity.z = 0.0
	
	if abs(wish_axis.z) > 0.1:
		var is_up: bool = Vector3.UP.dot(-basis.z) > -0.2
		body.linear_velocity.y = sign(wish_axis.z) * (climb_speed if is_up else -climb_speed)
	elif !is_jump:
		body.linear_velocity.y = 0.0
	
	if is_jump or (is_ground and body.linear_velocity.y < 0.0):
		body.linear_velocity.y -= accel_gravity * dt
		
		if abs(wish_axis.z) > 0.1 || abs(wish_axis.x) > 0.1:
			var forward: Vector3 = Vector3.UP.cross(basis.x)
			var left: Vector3 = Vector3.UP.cross(-basis.z)
			var direction: Vector3 = (forward * wish_axis.z + left * wish_axis.x).normalized()
			var strafe: Vector3 = direction * strafe_speed
			
			body.linear_velocity.x = strafe.x
			body.linear_velocity.z = strafe.z
		
		return
	
	if abs(wish_axis.x) > 0.1:
		var left: Vector3 = Vector3.UP.cross(-basis.z)
		var direction: Vector3 = (left * wish_axis.x).normalized()
		var strafe: Vector3 = direction * strafe_speed
		body.linear_velocity.x = strafe.x
		body.linear_velocity.z = strafe.z
	
