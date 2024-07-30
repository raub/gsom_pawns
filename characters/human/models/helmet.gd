extends Node3D


@onready var _animation_tree: AnimationTree = $AnimationTree

func set_direction(xz: Vector2) -> void:
	_animation_tree.set("parameters/Blend Crouch/blend_position", xz)
	_animation_tree.set("parameters/Blend Run/blend_position", xz)


func set_crouch(value: bool) -> void:
	_animation_tree.set("parameters/Blend2 Pose/blend_amount", 1.0 if value else 0.0)


func set_fly(value: bool) -> void:
	_animation_tree.set("parameters/Blend2 Fly/blend_amount", 1.0 if value else 0.0)


func jump() -> void:
	_animation_tree.set("parameters/One Jump/request", 1)
