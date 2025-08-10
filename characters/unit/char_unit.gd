extends Node3D
class_name CharUnit

const __STEP_INTERVAL: int = 400
const __STEP_MINSPEED: float = 5.0
const __STEP_MINSPEED_SQ: float = __STEP_MINSPEED * __STEP_MINSPEED

var __team: String = "none"
@export var team: String = "none":
	get:
		return __team
	set(v):
		__team = v
		__assign_team()


var pawn: GsomPawn = null:
	get:
		return __pawn

var __prev_step_time: int = 0

@onready var __pawn: GsomPawn = $GsomPawn
@onready var __steps: Node = $Steps

static var __units: Array[GsomPawn] = []


static func get_units() -> Array[GsomPawn]:
	return __units


func _ready() -> void:
	__units.append(__pawn)
	__assign_team()


func _exit_tree() -> void:
	__units.erase(__pawn)


func _process(_dt: float) -> void:
	__step()


func __assign_team() -> void:
	if __pawn:
		__pawn.set_trait("team", __team)


func __step() -> void:
	var time_now: int = Time.get_ticks_msec()
	
	if time_now - __prev_step_time < __STEP_INTERVAL:
		return
	
	var is_ground: bool = pawn.get_state("on_ground", false)
	if !is_ground:
		return
	
	var velocity_xz: Vector2 = Vector2(__pawn.linear_velocity.x, __pawn.linear_velocity.z)
	if velocity_xz.length_squared() < __STEP_MINSPEED_SQ:
		return
	
	__prev_step_time = time_now
	
	var count: int = __steps.get_child_count()
	var rand_idx: int = randi_range(0, count - 1)
	var player := __steps.get_child(rand_idx) as AudioStreamPlayer3D
	player.play()
