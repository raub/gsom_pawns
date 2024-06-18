extends Node3D


## The body has finished the '_physics_process' logic. This is the right time
## to fetch the position.
signal moved(pos: Vector3, head_y: float)

var head_y: float = 0.0:
	get:
		return _gsom_pawn_rigid.head_y


var hull: String = "Walk":
	get:
		return _gsom_pawn_rigid.hull
	set(v):
		_gsom_pawn_rigid.hull = v


var wish_axis: Vector3 = Vector3.ZERO:
	get:
		return _gsom_pawn_rigid.wish_axis
	set(v):
		_gsom_pawn_rigid.wish_axis = v


var head_basis: Basis = Basis.IDENTITY:
	get:
		return _gsom_pawn_rigid.head_basis
	set(v):
		_gsom_pawn_rigid.head_basis = v


@onready var _gsom_pawn_rigid: GsomPawnRigid = $GsomPawnRigid


func _ready() -> void:
	_gsom_pawn_rigid.moved.connect(
		func (pos: Vector3, y: float) -> void: moved.emit(pos, y),
	)
