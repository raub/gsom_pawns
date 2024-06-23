@tool
extends Node
class_name GsomPawnRigid

## Physics-based RigidBody3D pawn.
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

const _SceneRigid: PackedScene = preload("./pawn_rigid_impl.tscn")


## The body has finished the '_physics_process' logic. This is the right time
## to fetch the position.
signal moved(pos: Vector3, head_y: float)

## The body has just hit the ground with the specified vertical speed.
## You can use it to apply fall damage or play sounds.
signal hit_ground(speedY: float)

## The body has changed its shape.
signal changed_hull(hull: String)


## Global coefficient for [code]delta[/code] time
static var time_k_global: float = 1.0


## Local coefficient for [code]delta[/code] time of this pawn
@export var time_k: float = 1.0


## Limits what slopes are still considered ground.
## Higher values will cause even small slopes to be considered steep.
@export_range(0.2, 0.9) var slope_normal_y: float = 0.75


## How quickly the head moves between hulls.
@export var head_speed: float = 1.0


## Get current speed from the latest recorded velocity value.
var speed: float = 0.0:
	get:
		var hor := Vector2(_vell.x, _vell.z)
		return hor.length()


var _hull_next: String = ""
var _hull: String = "Walk"
## Name of the current pawn shape "hull".
@export var hull: String = "Walk":
	get:
		return _hull
	set(v):
		_hull_next = v
		_assign_hull()


## Assign this mass to the underlying rigid body.
@export_range(10.0, 200.0) var mass: float = 80.0


## Change this to make the body move. Rotation is controlled separately by [code]head_basis[/code].
##
## The body does NOT handle input and does NOT make assumptions regarding how it is handled.
## It may as well be AI who changes this value.
## [br]
## ● -Z is forward
## ● -X is left
## ● +Y is jump, -Y is duck
## [codeblock]
## wish_axis = ( # this should help
## 	Vector3.FORWARD * Input.get_axis("action_back", "action_forward")
## 	+ Vector3.LEFT * Input.get_axis("action_right", "action_left")
## 	+ Vector3.UP * Input.get_axis("action_duck", "action_jump")
## )
## [/codeblock]
var wish_axis := Vector3.ZERO


## Change this as the camera rotates.
##
## The body will match the rotation with [code]wish_axis[/code]. This is separated
## for both convenience and ability to adjust for slopes.
## [br]
## [codeblock]
## head_basis = camera.global_transform.basis
## [/codeblock]
var head_basis := Basis.IDENTITY


var _isGround: bool = false
## Get the latest recorded state of touching the ground.
var is_ground: bool = false:
	get:
		return _isGround


## Get the actual physical body object.
var body: RigidBody3D = null:
	get:
		return _body


var _head_y_prev: float = 0.0
var _head_y: float = 0.0
## Get the animated head/eye/camera position Y.
##
## When switching between hulls, the head position may change. E.g. from walking
## to crouching, to crawling, to swimming, etc. So the current Y is animated from
## one position to another with the speed of [code]head_speed[/code].
var head_y: float = _head_y:
	get:
		return _head_y


var _vell := Vector3.ZERO
var _pendingTossVel := Vector3.ZERO
var _hasPendingTp := false
var _pendingTpPos := Vector3.ZERO
var _parent: Node3D = null

# The nodes below are populated after `_SceneRigid` is instantiated in `_ready`
var _body: RigidBody3D = null


func _ready() -> void:
	_body = _SceneRigid.instantiate()
	_body.mass = mass
	add_child(_body)
	
	_parent = get_parent() as Node3D
	if !_parent:
		push_error("Parent must be a Node3D.")
	
	_body.global_position = _parent.global_position
	
	
	if Engine.is_editor_hint():
		return
	
	_hull_next = _hull
	_hull = ""
	_assign_hull()


func teleport(pos: Vector3) -> void:
	_hasPendingTp = true
	_pendingTpPos = pos


func toss(velocity: Vector3) -> void:
	_pendingTossVel += velocity


func _assign_hull() -> void:
	if _hull == _hull_next or !_hull_next or !_body:
		return
	
	var node := _body.get_node(_hull_next) as GsomPawnHull
	if !node or !(node is GsomPawnHull):
		push_error("Hull '%s' not found in pawn." % _hull_next)
		return
	
	if !node._check_enter():
		return
	
	if _hull:
		var node_prev := _body.get_node(_hull) as GsomPawnHull
		node_prev._exit_hull(self)
	else:
		_head_y = node._get_head_y()
	
	_hull = _hull_next
	node._enter_hull(self)


func _process(_dt: float) -> void:
	if !Engine.is_editor_hint():
		_parent.global_position = _body.global_position
		return
	
	_body.global_position = _parent.global_position


func _do_process(dt: float) -> void:
	_assign_hull()
	
	if !_hull:
		_head_y = 0.0
		return
	
	var node := _body.get_node(_hull) as GsomPawnHull
	var target_y: float = node._get_head_y()
	if target_y > _head_y:
		_head_y = min(_head_y + head_speed * dt, target_y)
	else:
		_head_y = max(_head_y - head_speed * dt, target_y)
	
	node._do_process(dt)


func _do_integrate(state: PhysicsDirectBodyState3D) -> void:
	_body.linear_velocity += _pendingTossVel
	_pendingTossVel = Vector3.ZERO
	
	if !_hull:
		return
	
	var node := _body.get_node(_hull) as GsomPawnHull
	node._do_integrate(self, state)


func _do_physics(dt: float) -> void:
	if _hasPendingTp:
		_body.linear_velocity = Vector3.ZERO
		_body.global_position = _pendingTpPos
		_hasPendingTp = false
		_pendingTpPos = Vector3.ZERO
		moved.emit(_body.global_position, _head_y)
		return
	
	if !_hull:
		return
	
	var node := _body.get_node(_hull) as GsomPawnHull
	node._do_physics(self, dt)
	
	_vell = _body.linear_velocity
	_parent.global_position = _body.global_position
	
	moved.emit(_body.global_position, _head_y)
