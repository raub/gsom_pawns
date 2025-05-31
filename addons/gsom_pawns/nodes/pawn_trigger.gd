@icon("./pawn_trigger.svg")
extends Node
class_name GsomPawnTrigger

## Attach a trigger to Area3D. Depending on behavior,
## it will trigger a signal on all entering and/or exiting pawns.
##
## The additional trigger data can be assigned separately for enter and exit.

## Types of pawn trigger behavior.
enum TriggerBehavior {
	## Default: trigger when pawn enters.
	ON_ENTER,
	## Inverse: trigger when pawn exits.
	ON_EXIT,
	## Trigger both when pawn enters and exits.
	ON_ENTER_AND_EXIT,
}


## Trigger name to emit.
@export var trigger_name: String = ""

## Trigger value passed on pawn enter. Default is [code]{}[/code], empty dictionary.
@export var value_enter: Dictionary = {}

## Trigger value passed on pawn exit. Default is [code]{}[/code], empty dictionary.
@export var value_exit: Dictionary = {}

## When the trigger should emit signal.
@export var behavior: TriggerBehavior = TriggerBehavior.ON_ENTER

## Doesn't do anything, when disabled.
@export var disabled := false


func _ready() -> void:
	_attach()


func _attach() -> void:
	var parent: Area3D = get_parent() as Area3D
	if !parent:
		return
	
	parent.body_entered.connect(_on_entered)
	parent.body_exited.connect(_on_exited)


func _trigger_enter(pawn: GsomPawn) -> void:
	pawn.trigger(trigger_name, value_enter)


func _trigger_exit(pawn: GsomPawn) -> void:
	pawn.trigger(trigger_name, value_enter)


func _on_entered(body: Node3D) -> void:
	if disabled:
		return
	
	if behavior == TriggerBehavior.ON_EXIT:
		return
	
	var pawn := body.get_parent() as GsomPawn
	if !pawn:
		return
	
	_trigger_enter(pawn)


func _on_exited(body: Node3D) -> void:
	if disabled:
		return
	
	if behavior == TriggerBehavior.ON_ENTER:
		return
	
	var pawn := body.get_parent() as GsomPawn
	if !pawn:
		return
	
	_trigger_exit(pawn)
