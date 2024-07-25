@icon("./pawn_handler.svg")
extends Node
class_name GsomPawnHandler


## Disabled handlers are skipped.
@export var disabled := false

## Only process while in these envs. Ignored if empty.
@export var include_envs: PackedStringArray = []

## Prevent processing while the body is in these envs
@export var exclude_envs: PackedStringArray = []

## Only process while in these states. Ignored if empty.
@export var include_states: PackedStringArray = []

## Prevent processing while the body is in these states
@export var exclude_states: PackedStringArray = []


## Reimplement this to update the body on [code]_process[/code].
func _do_process(_pawn: GsomPawn, _dt: float) -> void:
	pass


## Reimplement this to update the body on [code]_integrate_forces[/code].
func _do_integrate(_pawn: GsomPawn, _state: PhysicsDirectBodyState3D) -> void:
	pass


## Reimplement this to update the body on [code]_physics_process[/code].
func _do_physics(_pawn: GsomPawn, _delta: float) -> void:
	pass
