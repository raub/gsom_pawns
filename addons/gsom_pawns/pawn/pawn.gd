@tool
extends Node
class_name GsomPawn

## The GsomPawn framework core.
##
## GsomPawn node is designed for actors that can be controlled by players or AI.
## A pawn is the physical representation of a player or AI entity within the world.
## The pawn determines how the entity interacts with the world in terms of
## collisions and other physical interactions.
## Some types of games may not have a visible player mesh or avatar within the game.
## Regardless, the Pawn still represents the physical location, rotation, etc. of
## a player or entity within the game.
## You will need a Controller to possess a pawn and generate input signals for it.


## The pawn has finished the '_physics_process' logic. This is the right time
## to use the position to update cameras or other stuff.
signal moved(pos: Vector3)

## The body changed its linear speed - only emits if [code]track_accel_linear[/code].
signal accelerated_linear(dv: Vector3)

## The body changed its angular speed - only emits if [code]track_accel_angular[/code].
signal accelerated_angular(dv: Vector3)

## The relative position of the head changed.
signal moved_head(head_y: float)

## The body has received or produced an event with optional data.
signal triggered(trigger_name: String, value: Variant)


const _SCENE_DEFAULT: PackedScene = preload("./pawn_human.tscn")

var _scene: PackedScene = _SCENE_DEFAULT
## Scene that will be instantiated for this pawn
@export var scene: PackedScene = _SCENE_DEFAULT:
	get:
		return _scene
	set(v):
		_scene = v
		_assign_scene()


## How quickly the head moves between hulls.
@export var head_speed: float = 1.0


## If the pawn needs to track its linear acceleration.
@export var track_accel_linear: bool = false


## If the pawn needs to track its angular acceleration.
@export var track_accel_angular: bool = false


## If the pawn needs to track its linear acceleration.
@export var has_velocity_linear: bool = false


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


## Set this value to define the intended head height of the body.
## When this value is set from [code]_ready[/code], it will be applied
## immediately without animation.
var head_y_target: float = 0.0

var _head_y: float = 0.0
## Get the animated head/eye/camera position Y.
##
## This value is animated towards [code]head_y_target[/code]
## with the speed of [code]head_speed[/code].
var head_y: float = _head_y:
	get:
		return _head_y


var _envs := {}
var _actions := {}
var _states := {}
var _parent: Node3D = null


func _ready() -> void:
	_parent = get_parent() as Node3D
	if !_parent:
		push_error("Parent must be a Node3D.")
	
	_assign_scene()


func _assign_scene() -> void:
	if !_parent:
		return
	
	if _body:
		remove_child(_body)
		_body.queue_free()
	
	if !_scene:
		push_error("The `scene` is not set.")
		_scene = _SCENE_DEFAULT
		
	_body = _scene.instantiate()
	if !(_body is Node3D):
		push_error("The `scene` must be a Node3D.")
		_scene = _SCENE_DEFAULT
		_body = _scene.instantiate()
	add_child(_body)
	
	_head_y = head_y_target
	_body.position = _parent.global_position


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


## Erase the input value.
func erase_action(name: String) -> bool:
	return _actions.erase(name)


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


## Check if the env hint exists.
func has_env(name: String) -> bool:
	return _envs.has(name)


## Erase the env hint by name.
func erase_env(name: String) -> bool:
	return _envs.erase(name)


## Framework method, should be called by [code]scene[/code] instance on [code]_integrate_forces[/code].
func do_integrate(state: PhysicsDirectBodyState3D) -> void:
	for child: Node in get_children():
		if child is GsomPawnHandler and !child.disabled:
			child._do_integrate(self, state)


## Framework method, should be called by [code]scene[/code] instance on [code]_process[/code].
func do_process(dt: float) -> void:
	for child: Node in get_children():
		if child is GsomPawnHandler and !child.disabled:
			child._do_process(self, dt)


## Framework method, should be called by [code]scene[/code] instance on [code]_physics_process[/code].
func do_physics(dt: float) -> void:
	for child: Node in get_children():
		if child is GsomPawnHandler and !child.disabled:
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
	
	_parent.global_position = _body.position
	moved.emit(_body.position)


func _process(dt: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _head_y == head_y_target:
		return
	
	if head_y_target > _head_y:
		_head_y = min(_head_y + head_speed * dt, head_y_target)
	else:
		_head_y = max(_head_y - head_speed * dt, head_y_target)
	
	moved_head.emit(_head_y)


func _physics_process(dt: float) -> void:
	if Engine.is_editor_hint():
		_body.position = _parent.global_position
