extends GsomPawnEnv
class_name SnapEnv

func _ready() -> void:
	attach()
	env_value = { "target": get_parent() }
