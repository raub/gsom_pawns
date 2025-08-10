extends Node3D
class_name ModelVtol

@onready var __animation_player: AnimationPlayer = $AnimationPlayer
@onready var __gpu_particles_3d: GPUParticles3D = $Engine/GPUParticles3D

var __down_cache: bool = false
var __ground_cache: bool = true

func set_down(value: bool) -> void:
	if __down_cache == value:
		return
	__down_cache = value
	__animation_player.play("engine_down" if value else "engine_up")


func set_ground(value: bool) -> void:
	if __ground_cache == value:
		return
	__ground_cache = value
	__animation_player.play("legs_down" if value else "legs_up")


func set_power(value: float) -> void:
	if absf(value) < 0.1:
		__gpu_particles_3d.draw_pass_1.surface_get_material(0).set("albedo_color", Color("#ffb121"))
		return
	if value < -0.1:
		__gpu_particles_3d.draw_pass_1.surface_get_material(0).set("albedo_color", Color("#6b170e"))
		return
	if value > 0.1:
		__gpu_particles_3d.draw_pass_1.surface_get_material(0).set("albedo_color", Color("#69c9d6"))
		return
