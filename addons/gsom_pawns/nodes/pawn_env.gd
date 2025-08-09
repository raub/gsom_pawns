@icon("./pawn_env.svg")
extends Node
class_name GsomPawnEnv

## Environment description for GsomPawn
##
## Attach an env to Area3D. Depending on behavior,
## it will apply and/or remove an env field on all entering and/or exiting pawns.
## The default env data is [code]{}[/code], empty dictionary.

## Types of pawn env behavior.
enum EnvBehavior {
	## Only apply the Env when pawn enters the area, do nothing on exit.
	ENTER_APPLY,
	## Only remove the Env when pawn enters the area, do nothing on exit.
	ENTER_REMOVE,
	## Default: apply when pawn enters, remove on exit.
	ENTER_APPLY_EXIT_REMOVE,
	## Inverse: remove when pawn enters, apply on exit.
	ENTER_REMOVE_EXIT_APPLY,
	## Only apply the Env when pawn exits the area, do nothing on enter.
	EXIT_APPLY,
	## Only remove the Env when pawn enters the area, do nothing on enter.
	EXIT_REMOVE,
}


## Env info field name to edit.
@export var env_name: String = ""

## Env value to be assigned. Default is [code]{}[/code], empty dictionary.
@export var env_value: Dictionary = {}

## When the Env should be applied and removed.
@export var behavior: EnvBehavior = EnvBehavior.ENTER_APPLY_EXIT_REMOVE

## Doesn't do anything, when disabled.
@export var disabled := false


func _ready() -> void:
	attach()


## Call this from _ready() if you extend this class.
func attach() -> void:
	var parent: Node = get_parent()
	if parent is not Area3D:
		return
	
	var parentArea: Area3D = parent
	parentArea.body_entered.connect(__on_entered)
	parentArea.body_exited.connect(__on_exited)


## Called to assign the env value.
##
## Override this for custom envs.
func _apply_env(pawn: GsomPawn) -> void:
	pawn.set_env(env_name, env_value)


## Called to remove the env value.
##
## Override this for custom envs.
func _erase_env(pawn: GsomPawn) -> void:
	pawn.erase_env(env_name)


func __on_entered(body: Node3D) -> void:
	if disabled:
		return
	
	if behavior == EnvBehavior.EXIT_APPLY or behavior == EnvBehavior.EXIT_REMOVE:
		return
	
	var pawn := body.get_parent() as GsomPawn
	if !pawn:
		return
	
	if behavior == EnvBehavior.ENTER_APPLY or behavior == EnvBehavior.ENTER_APPLY_EXIT_REMOVE:
		_apply_env(pawn)
		return
	
	if behavior == EnvBehavior.ENTER_REMOVE or behavior == EnvBehavior.ENTER_REMOVE_EXIT_APPLY:
		_erase_env(pawn)
		return


func __on_exited(body: Node3D) -> void:
	if disabled:
		return
	
	if behavior == EnvBehavior.ENTER_APPLY or behavior == EnvBehavior.ENTER_REMOVE:
		return
	
	var pawn := body.get_parent() as GsomPawn
	if !pawn:
		return
	
	if behavior == EnvBehavior.EXIT_APPLY or behavior == EnvBehavior.ENTER_REMOVE_EXIT_APPLY:
		_apply_env(pawn)
		return
	
	if behavior == EnvBehavior.EXIT_REMOVE or behavior == EnvBehavior.ENTER_APPLY_EXIT_REMOVE:
		_erase_env(pawn)
		return
