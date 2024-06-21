extends GsomPawnHull

## Limits what slopes are still considered ground.
## Higher values will cause even small slopes to be considered steep.
@export_range(0.2, 0.9) var slope_normal_y: float = 0.75

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
## physics reference. The most obvious use-case is acceleration during bhop.
@export var max_speed_fly: float = 0.73 # 30 unit/sec

## Acceleration multiplier for running. The [code]max_speed_run[/code] is
## multiplied by this to get the final acceleration.
@export var accel_run_k: float = 12.0

## Acceleration multiplier for running. The [code]max_speed_run[/code]
## (and not [code]max_speed_fly[/code]!) is
## multiplied by this to get the final acceleration.
@export var accel_fly_k: float = 12.0

## This speed is directly assigned to the body when it performs a jump.
@export var speed_jump: float = 5.9 # validate per 44 (and 62) unit - 1.07 m (and 1.5 m)

## Decrease the Y component of velocity by this much every second.
##
## Somehow it's not "9.8", just feels better this way. By default Half-Life 1 has
## "sv_gravity 800" ~ 19.5 m/s2, so not far off.
@export var accel_gravity: float = 18.0

## How soon whe body will stop with no input - it loses that many m/s from its speed.
@export var stop_speed: float = 2.45 # ~100 unit/sec


var _is_debug_mesh := true
## Show the debug mesh (default to true so you can see the pawn when added)
@export var is_debug_mesh := true:
	get:
		return _is_debug_mesh
	set(v):
		_is_debug_mesh = v
		_assign_is_debug_mesh()

var _normal := Vector3.UP

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _cast: ShapeCast3D = $Cast
@onready var _cast_up: ShapeCast3D = $CastUp
@onready var _ray: RayCast3D = $Ray


func _ready() -> void:
	_assign_is_debug_mesh()

	var rigid := get_parent() as RigidBody3D
	if rigid:
		_cast_up.add_exception(rigid)
		_cast.add_exception(rigid)
		_ray.add_exception(rigid)
	
	_exit_hull(null)


func _check_enter() -> bool:
	return !_cast_up.is_colliding()


func _check_exit() -> bool:
	return true


func _enter_hull(_pawn: GsomPawnRigid) -> void:
	visible = true
	disabled = false
	_cast.enabled = true
	_cast_up.enabled = false
	_ray.enabled = true


func _exit_hull(_pawn: GsomPawnRigid) -> void:
	visible = false
	disabled = true
	_cast.enabled = false
	_cast_up.enabled = true
	_ray.enabled = false


func _get_head_y() -> float:
	return 1.55


func _do_process(dt: float) -> void:
	pass


func _do_integrate(pawn: GsomPawnRigid, state: PhysicsDirectBodyState3D) -> void:
	var rigid: RigidBody3D = pawn.body
	
	var dt: float = state.step
	var direction := Vector3.ZERO
	
	if abs(pawn.wish_axis.z) > 0.1 || abs(pawn.wish_axis.x) > 0.1:
		var basisGlobal: Basis = pawn.head_basis
		var forward: Vector3 = _normal.cross(basisGlobal.x)
		var left: Vector3 = _normal.cross(-basisGlobal.z)
		direction = (forward * pawn.wish_axis.z + left * pawn.wish_axis.x).normalized()
	
	var accel_fly: float = accel_fly_k * max_speed_run
	
	if pawn._isGround:
		if pawn.wish_axis.y > 0.5:
			rigid.linear_velocity.y = speed_jump
			if direction.length():
				var curspeed: float = rigid.linear_velocity.dot(direction)
				var addspeed: float = clampf(max_speed_fly - curspeed, 0, accel_fly * dt)
				rigid.linear_velocity += direction * addspeed
		else:
			var curspeed1: float = rigid.linear_velocity.length()
			var control: float = stop_speed if curspeed1 < stop_speed else curspeed1
			var newspeed: float = clampf(curspeed1 - 4.0 * control * dt, 0.0, curspeed1)
			var fract: float = newspeed / curspeed1 if curspeed1 else 0.0
			
			rigid.linear_velocity *= fract
			if direction.length():
				var wishspeed: float = max_speed_run
				var curspeed: float = rigid.linear_velocity.dot(direction)
				var accel_run: float = accel_run_k * max_speed_run
				var addspeed: float = clampf(wishspeed - curspeed, 0, accel_run * dt)
				rigid.linear_velocity += direction * addspeed
	else:
		rigid.linear_velocity.y -= accel_gravity * dt
		if direction.length():
			var curspeed: float = rigid.linear_velocity.dot(direction)
			var addspeed: float = clampf(max_speed_fly - curspeed, 0, accel_fly * dt)
			rigid.linear_velocity += direction * addspeed


# Detect the isGround state from collision results from shape and ray casts
# If was in air and hit ground - emits `pawn.hit_ground`
func _do_physics(pawn: GsomPawnRigid, _delta: float) -> void:
	var rigid: RigidBody3D = pawn.body
	
	var result: Array = _cast.collision_result
	var wasGround: bool = pawn._isGround
	pawn._isGround = false
	_normal = Vector3.UP
	
	if !result.size():
		return
	
	var max_y: float = 0.0
	for item: Dictionary in result:
		max_y = max(item.normal.y, max_y)
	if max_y < slope_normal_y:
		return
	
	_normal.y = max_y
	pawn._isGround = true
	if !wasGround:
		var dvell: Vector3 = (pawn._vell - rigid.linear_velocity)
		pawn.hit_ground.emit(dvell.y)
	if _ray.is_colliding():
		_normal = _ray.get_collision_normal()


func _assign_is_debug_mesh() -> void:
	if _mesh:
		_mesh.visible = _is_debug_mesh
