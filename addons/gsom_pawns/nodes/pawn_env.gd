@icon("./pawn_env.svg")
extends Node
class_name GsomPawnEnv

## Attach an env to Area3D. Depending on behavior,
## it will apply and/or remove an env field on all entering and/or exiting pawns.
##
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
	var parent: Area3D = get_parent() as Area3D
	if !parent:
		push_error("Parent must be an Area3D.")
		return
	
	parent.body_entered.connect(_on_entered)
	parent.body_exited.connect(_on_exited)


func _on_entered(body: Node3D) -> void:
	if disabled:
		return
	
	if behavior == EnvBehavior.EXIT_APPLY or behavior == EnvBehavior.EXIT_REMOVE:
		return
	
	var pawn := body.get_parent() as GsomPawn
	if !pawn:
		return
	
	if behavior == EnvBehavior.ENTER_APPLY or behavior == EnvBehavior.ENTER_APPLY_EXIT_REMOVE:
		pawn.set_env(env_name, true)
		return
	
	if behavior == EnvBehavior.ENTER_REMOVE or behavior == EnvBehavior.ENTER_REMOVE_EXIT_APPLY:
		pawn.erase_env(env_name)
		return


func _on_exited(body: Node3D) -> void:
	if disabled:
		return
	
	if behavior == EnvBehavior.ENTER_APPLY or behavior == EnvBehavior.ENTER_REMOVE:
		return
	
	var pawn := body.get_parent() as GsomPawn
	if !pawn:
		return
	
	if behavior == EnvBehavior.EXIT_APPLY or behavior == EnvBehavior.ENTER_REMOVE_EXIT_APPLY:
		pawn.set_env(env_name, true)
		return
	
	if behavior == EnvBehavior.EXIT_REMOVE or behavior == EnvBehavior.ENTER_APPLY_EXIT_REMOVE:
		pawn.erase_env(env_name)
		return
