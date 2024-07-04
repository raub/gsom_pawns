@tool
extends Node
class_name GsomPawn

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


## The body has finished the '_physics_process' logic. This is the right time
## to fetch the position.
signal moved(pos: Vector3)

## The body changed its linear speed - only emits if [code]wish_axis[/code]
signal accelerated_linear(dv: Vector3)
signal accelerated_angular(dv: Vector3)

## The head position changed
signal moved_head(head_y: float)

## The body has received or produced an event with optional data.
signal triggered(name: String, value: Variant)


const _SCENE_DEFAULT: PackedScene = preload("./pawn_human.tscn")

## Scene that will be instantiated for this pawn
@export var scene: PackedScene = _SCENE_DEFAULT


## How quickly the head moves between hulls.
@export var head_speed: float = 1.0


## If the pawn needs to track its linear acceleration.
@export var track_accel_linear: bool = false


## If the pawn needs to track its angular acceleration.
@export var track_accel_angular: bool = false


## If the pawn needs to track its linear acceleration.
@export var has_velocity_linear: bool = true


## If the pawn needs to track its angular acceleration.
@export var has_velocity_angular: bool = false


## Get position of the body.
var position: Vector3 = Vector3.ZERO:
	get:
		return _body.position


var _cached_vell := Vector3.ZERO
## Linear velocity vector, only updated if [code]has_velocity_linear[/code].
var linear_velocity: Vector3 = Vector3.ZERO:
	get:
		return _cached_vell


var _cached_vela := Vector3.ZERO
## Angular velocity vector, only updated if [code]has_velocity_angular[/code].
var angular_velocity: Vector3 = Vector3.ZERO:
	get:
		return _cached_vela


# Cache the child physics body after instantiation
var _body: Node3D = null
## Get the cached physical body object as instantiated from [code]scene[/code].
var body: Node3D = null:
	get:
		return _body


var _head_y: float = 0.0
## Get the animated head/eye/camera position Y.
##
## When switching between hulls, the head position may change. E.g. from walking
## to crouching, to crawling, to swimming, etc. So the current Y is animated from
## one position to another with the speed of [code]head_speed[/code].
var head_y: float = _head_y:
	get:
		return _head_y


var _envs := {}
var _actions := {}
var _states := {}
var _parent: Node3D = null


func _ready() -> void:
	_body = scene.instantiate()
	if _body is Node3D:
		add_child(_body)
		if !Engine.is_editor_hint():
			_head_y = body.head_y
	else:
		push_error("The `scene` must be a Node3D.")
		_body = _SCENE_DEFAULT.instantiate()
		add_child(_body)
	
	_parent = get_parent() as Node3D
	if !_parent:
		push_error("Parent must be a Node3D.")
	
	_body.global_position = _parent.global_position


## Set an arbitrary input status. Such as [code]"jump", true[/code], or [code]"forward", 0.5[/code]
##
## The inputs are to be read by handlers to determine the evolution of the physical model.
func set_action(name: String, value: Variant) -> void:
	_actions[name] = value


## Clear all input statuses.
func reset_actions() -> void:
	_actions.clear()


## Fetch an arbitrary input status by name.
##
## If the status has never been set or [code]reset_actions[/code] has just been called,
## this method returns [code]null[/code] - that should be accounted for.
## The inputs are to be read by handlers to determine the evolution of the physical model.
func get_action(name: String, default_value: Variant = null) -> Variant:
	if !_actions.has(name):
		return default_value
	return _actions[name]


## Check if the input action exists.
func has_action(name: String) -> bool:
	return _actions.has(name)


## Store arbitrary environmental hints for the physical model or character.
##
## The relevant hints may be read by handlers or external character wrappers,
## and also written to by either party. Use it to know such things as
## - am I in water?
## - am I on ground?
## - am I in air?
## - what is the ground material? - sound/movement adjustment
## - can I stand up?
## - custom movement handling: jump pads, wind, conveyors, etc.
## - trigger actions/damage in certain areas
func set_env(name: String, value: Variant) -> void:
	_envs[name] = value


## Clears all env hints.
func reset_envs() -> void:
	_envs.clear()


## Fetch an arbitrary env hint by name.
##
## If the hint has never been set or [code]reset_envs[/code] has just been called,
## this method returns [code]null[/code] - that should be accounted for.
func get_env(name: String, default_value: Variant = null) -> Variant:
	if !_envs.has(name):
		return default_value
	return _envs[name]


## Framework method, should be called by [code]scene[/code] instance on [code]_integrate_forces[/code].
func do_integrate(state: PhysicsDirectBodyState3D) -> void:
	for child: Node in get_children():
		if child is GsomPawnHandler:
			child._do_integrate(self, state)


## Framework method, should be called by [code]scene[/code] instance on [code]_process[/code].
func do_process(dt: float) -> void:
	for child: Node in get_children():
		if child is GsomPawnHandler:
			child._do_process(self, dt)


## Framework method, should be called by [code]scene[/code] instance on [code]_physics_process[/code].
func do_physics(dt: float) -> void:
	for child: Node in get_children():
		if child is GsomPawnHandler:
			child._do_physics(self, dt)
	
	if track_accel_linear and has_velocity_linear:
		var dvell: Vector3 = (_cached_vell - _body.linear_velocity)
		if dvell.length_squared() > 0.0001:
			accelerated_linear.emit(dvell)
	
	if has_velocity_linear:
		_cached_vell = _body.linear_velocity
	
	if track_accel_angular and has_velocity_angular:
		var dvela: Vector3 = (_cached_vela - _body.angular_velocity)
		if dvela.length_squared() > 0.0001:
			accelerated_angular.emit(dvela)
			_cached_vela = _body.angular_velocity
	
	if has_velocity_angular:
		_cached_vela = _body.angular_velocity
	
	moved.emit(_body.global_position)


func _process(dt: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var target_y: float = _body.head_y
	if _head_y == target_y:
		return
	
	if target_y > _head_y:
		_head_y = min(_head_y + head_speed * dt, target_y)
	else:
		_head_y = max(_head_y - head_speed * dt, target_y)
	
	moved_head.emit(_head_y)


func _physics_process(dt: float) -> void:
	if Engine.is_editor_hint():
		_body.global_position = _parent.global_position
		return
	
	_parent.global_position = _body.global_position
	
	moved.emit(_body.global_position)
