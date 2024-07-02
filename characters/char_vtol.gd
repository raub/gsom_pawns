extends Node3D


var pawn: GsomPawn = null:
	get:
		return _pawn


@onready var _pawn: GsomPawn = $GsomPawn
@onready var _audio_engine: AudioStreamPlayer3D = $AudioEngine
@onready var _audio_power: AudioStreamPlayer3D = $AudioPower


func _ready() -> void:
	pass


func _process(_dt: float) -> void:
	_update_audio()


func _update_audio() -> void:
	var power_value: float = 0.0
	if pawn.get_action("jump", false):
		power_value += 1
	if pawn.get_action("duck", false):
		power_value -= 1
	
	if _audio_power.playing != (power_value > 0.0):
		_audio_power.playing = power_value > 0.0
	_audio_engine.pitch_scale = 1 + 0.2 * power_value
