extends Node3D
class_name CharVtol


var pawn: GsomPawn = null:
	get:
		return __pawn


@onready var __pawn: GsomPawn = $GsomPawn
@onready var __audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var __audio_power: AudioStreamPlayer3D = $AudioPower
@onready var __vtol_pivot: Node3D = $VtolPivot
@onready var __vtol: ModelVtol = $VtolPivot/Vtol


func _ready() -> void:
	__vtol.set_down(true)
	__vtol.set_ground(true)


func _process(_dt: float) -> void:
	var is_ground: bool = __pawn.get_state("on_ground", false)
	__vtol.set_ground(is_ground)
	
	var is_forward: bool = __pawn.get_action("sprint", false) or __pawn.get_action("forward", false)
	var is_up: bool = !is_ground and is_forward
	__vtol.set_down(!is_up)
	
	var power_value: float = 0.0
	if (!is_forward and pawn.get_action("jump", false)) or (!is_ground and is_forward):
		power_value += 1
	if pawn.get_action("duck", false):
		power_value -= 1
	__vtol.set_power(power_value)
	
	__vtol_pivot.rotation = __pawn.body.rotation
	
	__update_audio(power_value)


func __update_audio(power_value: float) -> void:
	if __audio_power.playing != (power_value > 0.0):
		__audio_power.playing = power_value > 0.0
	__audio_engine.pitch_scale = 1 + 0.2 * power_value
