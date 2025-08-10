extends RigidBody3D
class_name PawnHuman

const __HEAD_WALK: float = 1.55
const __HEAD_DUCK: float = 1.2


## Limits what slopes are still considered ground.
## Higher values will cause even small slopes to be considered steep.
@export_range(0.2, 0.9) var slope_normal_y: float = 0.75


var __pawn: GsomPawn = null
var __is_ground := false

var __normal := Vector3.UP
## Get the current body-to-ground normal
var normal: Vector3 = __normal:
	get:
		return __normal


@onready var __shape_walk: CollisionShape3D = $ShapeWalk
@onready var __shape_duck: CollisionShape3D = $ShapeDuck
@onready var __cast: ShapeCast3D = $Cast
@onready var __cast_up: ShapeCast3D = $CastUp
@onready var __ray: RayCast3D = $Ray
@onready var __marker_duck: Marker3D = $MarkerDuck
@onready var __marker_walk: Marker3D = $MarkerWalk


func _ready() -> void:
	__cast_up.add_exception(self)
	__cast.add_exception(self)
	__ray.add_exception(self)
	
	__pawn = get_parent() as GsomPawn
	if !__pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	__unduck()


func __duck() -> void:
	if __pawn.get_state("duck", false):
		return
	
	__pawn.set_state("duck", true)
	
	__shape_walk.disabled = true
	__shape_duck.disabled = false
	
	__cast_up.enabled = true
	
	__cast.position.y = __marker_duck.position.y
	__ray.position.y = __marker_duck.position.y
	
	__pawn.head_y_target = __HEAD_DUCK


func __unduck() -> void:
	if __cast_up.is_colliding() or !__pawn.get_state("duck", true):
		return
	
	__pawn.set_state("duck", false)
	
	# HACK: don't let the full shape pierce into floor
	if __is_ground:
		global_position.y += __shape_duck.position.y - 0.45
	
	__shape_walk.disabled = false
	__shape_duck.disabled = true
	
	__cast_up.enabled = false
	
	__cast.position.y = __marker_walk.position.y
	__ray.position.y = __marker_walk.position.y
	
	__pawn.head_y_target = __HEAD_WALK


# Detect the is_ground state from collision results from shape and ray casts
# If was in air and hit ground - emits `pawn.hit_ground`
func __update_ground_state() -> void:
	var result: Array = __cast.collision_result
	var was_ground: bool = __is_ground
	__is_ground = false
	__normal = Vector3.UP
	
	if !result.size():
		__pawn.set_state("normal", __normal)
		return
	
	var max_y := -Vector3.UP
	for item: Dictionary in result:
		if item.normal.y > max_y.y:
			max_y = item.normal
	
	var is_ray_colliding: bool = __ray.is_colliding()
	
	if max_y.y < slope_normal_y and (max_y.y > 0.0 || !is_ray_colliding):
		__pawn.set_state("normal", __normal)
		return
	
	__normal = max_y
	__is_ground = true
	
	if !was_ground:
		__pawn.trigger("hit_ground", { "speed": linear_velocity.y })
	
	if is_ray_colliding:
		__normal = __ray.get_collision_normal()
	
	__pawn.set_state("normal", __normal)


func _process(dt: float) -> void:
	__pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	__update_ground_state()
	
	__pawn.set_env("up_blocked", __cast_up.is_colliding())
	__pawn.set_state("on_ground", __is_ground)
	
	if __pawn.get_action("duck", false):
		__duck()
	else:
		__unduck()
	
	__pawn.do_physics(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	__pawn.do_integrate(state)
