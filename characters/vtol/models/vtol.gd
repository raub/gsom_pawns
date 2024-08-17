extends Node3D

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _gpu_particles_3d: GPUParticles3D = $Engine/GPUParticles3D

var _down_cache: bool = false
var _ground_cache: bool = true

func set_down(value: bool) -> void:
	if _down_cache == value:
		return
	_down_cache = value
	_animation_player.play("engine_down" if value else "engine_up")


func set_ground(value: bool) -> void:
	if _ground_cache == value:
		return
	_ground_cache = value
	_animation_player.play("legs_down" if value else "legs_up")


func set_power(value: float) -> void:
	if absf(value) < 0.1:
		_gpu_particles_3d.draw_pass_1.surface_get_material(0).set("albedo_color", Color("#ffb121"))
		return
	if value < -0.1:
		_gpu_particles_3d.draw_pass_1.surface_get_material(0).set("albedo_color", Color("#6b170e"))
		return
	if value > 0.1:
		_gpu_particles_3d.draw_pass_1.surface_get_material(0).set("albedo_color", Color("#69c9d6"))
		return
