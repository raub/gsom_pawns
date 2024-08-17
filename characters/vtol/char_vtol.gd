extends Node3D


var pawn: GsomPawn = null:
	get:
		return _pawn


@onready var _pawn: GsomPawn = $GsomPawn
@onready var _audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var _audio_power: AudioStreamPlayer3D = $AudioPower
@onready var _vtol_pivot: Node3D = $VtolPivot
@onready var _vtol: Node3D = $VtolPivot/Vtol


func _ready() -> void:
	_vtol.set_down(true)
	_vtol.set_ground(true)


func _process(_dt: float) -> void:
	var is_ground: bool = _pawn.get_state("on_ground", false)
	_vtol.set_ground(is_ground)
	
	var is_forward: bool = _pawn.get_action("sprint", false) or _pawn.get_action("forward", false)
	var is_up: bool = !is_ground and is_forward
	_vtol.set_down(!is_up)
	
	var power_value: float = 0.0
	if (!is_forward and pawn.get_action("jump", false)) or (!is_ground and is_forward):
		power_value += 1
	if pawn.get_action("duck", false):
		power_value -= 1
	_vtol.set_power(power_value)
	
	_vtol_pivot.rotation = _pawn.body.rotation
	
	_update_audio(power_value)


func _update_audio(power_value: float) -> void:
	if _audio_power.playing != (power_value > 0.0):
		_audio_power.playing = power_value > 0.0
	_audio_engine.pitch_scale = 1 + 0.2 * power_value
