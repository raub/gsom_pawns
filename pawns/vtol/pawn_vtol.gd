extends RigidBody3D


var _pawn: GsomPawn = null
var _is_ground := false

@onready var _cast_ground: ShapeCast3D = $CastGround


func _ready() -> void:
	_cast_ground.add_exception(self)
	
	_pawn = get_parent() as GsomPawn
	if !_pawn:
		push_error("Parent must be a GsomPawn.")
		return
	
	_pawn.head_y_target = 0.5


func _process(dt: float) -> void:
	_pawn.do_process(dt)


func _physics_process(dt: float) -> void:
	_update_ground_state()
	_pawn.set_state("on_ground", _is_ground)
	
	_pawn.do_physics(dt)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_pawn.do_integrate(state)

# Detect the isGround state from collision results from shape and ray casts
# If was in air and hit ground - emits `pawn.hit_ground`
func _update_ground_state() -> void:
	var result: Array = _cast_ground.collision_result
	var wasGround: bool = _is_ground
	_is_ground = false
	
	if !result.size():
		return
	
	_is_ground = true
	
	if !wasGround:
		_pawn.triggered.emit("hit_ground", { "speed": linear_velocity.y })
