@icon("./pawn_trigger.svg")
extends Node
class_name GsomPawnTrigger

## Trigger events for GsomPawn
##
## Attach a trigger to Area3D. Depending on behavior,
## it will trigger a signal on all entering and/or exiting pawns.
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
	attach()


## Call this from _ready() if you extend this class.
func attach() -> void:
	var parent: Node = get_parent()
	if parent is not Area3D:
		return
	
	var parent_area: Area3D = parent
	parent_area.body_entered.connect(__on_entered)
	parent_area.body_exited.connect(__on_exited)


## Called when a body enters the trigger.
##
## Override this for custom triggers.
func _trigger_enter(pawn: GsomPawn) -> void:
	pawn.trigger(trigger_name, value_enter)


## Called when a body exits from trigger.
##
## Override this for custom triggers.
func _trigger_exit(pawn: GsomPawn) -> void:
	pawn.trigger(trigger_name, value_exit)


func __on_entered(body: Node3D) -> void:
	if disabled or behavior == TriggerBehavior.ON_EXIT:
		return
	
	var parent: Node = body.get_parent()
	if parent is GsomPawn:
		var parent_pawn: GsomPawn = parent
		_trigger_enter(parent_pawn)


func __on_exited(body: Node3D) -> void:
	if disabled or behavior == TriggerBehavior.ON_ENTER:
		return
	
	var parent: Node = body.get_parent()
	if parent is GsomPawn:
		var parent_pawn: GsomPawn = parent
		_trigger_exit(parent_pawn)
