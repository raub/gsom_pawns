extends RigidBody3D


var __pawn: GsomPawn = null
var __is_ground := false

@onready var __cast_ground: ShapeCast3D = $CastGround


func _ready() -> void:
	__cast_ground.add_exception(self)
	
	__pawn = get_parent() as GsomPawn
	if !__pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	__pawn.head_y_target = 0.5


func _process(dt: float) -> void:
	__pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	__update_ground_state()
	__pawn.set_state("on_ground", __is_ground)
	
	__pawn.do_physics(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	__pawn.do_integrate(state)

# Detect the is_ground state from collision results from shape and ray casts
# If was in air and hit ground - emits `pawn.hit_ground`
func __update_ground_state() -> void:
	var result: Array = __cast_ground.collision_result
	var was_ground: bool = __is_ground
	__is_ground = false
	
	if !result.size():
		return
	
	__is_ground = true
	
	if !was_ground:
		__pawn.trigger("hit_ground", { "speed": linear_velocity.y })
