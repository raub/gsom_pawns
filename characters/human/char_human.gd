extends Node3D
class_name CharHuman

const __STEP_GROUND_INTERVAL: int = 400
const __STEP_GROUND_MINSPEED: float = 5.0
const __STEP_GROUND_MINSPEED_SQ: float = __STEP_GROUND_MINSPEED * __STEP_GROUND_MINSPEED

const __STEP_LADDER_INTERVAL: int = 600
const __STEP_LADDER_MINSPEED_SQ: float = 1.0

const __STEP_SWIM_INTERVAL: int = 2000


var pawn: GsomPawn = null:
	get:
		return __pawn

var __prev_step_ground_time: int = 0
var __prev_step_ladder_time: int = 0
var __prev_step_swim_time: int = 0

@onready var __pawn: GsomPawn = $GsomPawn
@onready var __steps_concrete: Node = $StepsConcrete
@onready var __steps_metal: Node = $StepsMetal
@onready var __steps_ladder: Node = $StepsLadder
@onready var __steps_swim: Node = $StepsSwim
@onready var __steps_wet: Node = $StepsWet
@onready var __helmet: ModelHelmet = $helmet


func _ready() -> void:
	__helmet.set_fly(false)
	__helmet.set_swim(false)
	__helmet.set_direction(Vector2.ZERO)
	__helmet.set_crouch(false)


func _process(_dt: float) -> void:
	__produce_step_sound()
	
	var view_basis: Basis = __pawn.get_action("basis", Basis.IDENTITY)
	var forward: Vector3 = Vector3.UP.cross(view_basis.x)
	var left: Vector3 = Vector3.UP.cross(-view_basis.z)
	global_transform.basis = Basis.looking_at(forward, Vector3.UP, true)
	
	var vel: Vector3 = __pawn.linear_velocity
	var speed: float = vel.length()
	var dir := Vector2(vel.x, vel.z).normalized()
	var dot_forward: float = Vector2(forward.x, forward.z).dot(dir)
	var dot_left: float = Vector2(left.x, left.z).dot(dir)
	
	var is_duck: bool = __pawn.get_state("duck", false)
	__helmet.position.y = 0.45 if is_duck else 0.0
	
	var anim_xz := Vector2(dot_forward, dot_left) * speed * 0.1
	__helmet.set_direction(Vector2(minf(1.0, anim_xz.x), minf(1.0, anim_xz.y)))
	__helmet.set_crouch(is_duck)
	
	var is_water: bool = pawn.has_env("water")
	__helmet.set_swim(is_water)
	if is_water:
		__helmet.set_fly(false)
		return
	
	var is_jump: bool = pawn.get_action("jump", false)
	var is_ground: bool = pawn.get_state("on_ground", false)
	
	__helmet.set_fly(!is_ground)
	
	if is_ground and is_jump:
		__helmet.jump()



func __produce_step_sound() -> void:
	var is_water: bool = pawn.has_env("water")
	if is_water:
		__try_step_swim()
		return
	
	var is_ground: bool = pawn.get_state("on_ground", false)
	if is_ground:
		__try_step_ground()
		return
	
	var is_ladder: bool = pawn.has_env("ladder")
	if is_ladder:
		__try_step_ladder()
		return


func __try_step_ground() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - __prev_step_ground_time < __STEP_GROUND_INTERVAL:
		return
	
	var velocity_xz: Vector2 = Vector2(__pawn.linear_velocity.x, __pawn.linear_velocity.z)
	if velocity_xz.length_squared() < __STEP_GROUND_MINSPEED_SQ:
		return
	
	__prev_step_ground_time = time_now
	
	var host_node: Node = __steps_concrete
	
	var surface: Dictionary = pawn.get_env("surface", {})
	if surface.has("material"):
		if surface.material == "metal":
			host_node = __steps_metal
		if surface.material == "water":
			host_node = __steps_wet
	
	var count: int = host_node.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := host_node.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()


func __try_step_ladder() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - __prev_step_ladder_time < __STEP_LADDER_INTERVAL:
		return
	
	if __pawn.linear_velocity.length_squared() < __STEP_LADDER_MINSPEED_SQ:
		return
	
	__prev_step_ladder_time = time_now
	
	var count: int = __steps_ladder.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := __steps_ladder.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()


func __try_step_swim() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - __prev_step_swim_time < __STEP_SWIM_INTERVAL:
		return
	
	__prev_step_swim_time = time_now
	
	var count: int = __steps_swim.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := __steps_swim.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()
