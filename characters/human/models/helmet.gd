extends Node3D
class_name ModelHelmet


@onready var __animation_tree: AnimationTree = $AnimationTree

func set_direction(xz: Vector2) -> void:
	__animation_tree.set("parameters/Blend Crouch/blend_position", xz)
	__animation_tree.set("parameters/Blend Run/blend_position", xz)


func set_crouch(value: bool) -> void:
	__animation_tree.set("parameters/Blend2 Pose/blend_amount", 1.0 if value else 0.0)


func set_fly(value: bool) -> void:
	__animation_tree.set("parameters/Blend2 Fly/blend_amount", 1.0 if value else 0.0)


func set_swim(value: bool) -> void:
	__animation_tree.set("parameters/Blend2 Swim/blend_amount", 1.0 if value else 0.0)


func jump() -> void:
	__animation_tree.set("parameters/One Jump/request", 1)
