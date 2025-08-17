extends GsomPawnEnv
class_name SnapEnv

var __offset_node_x: Node3D = null;

var __prev_offset_position: Vector3 = Vector3()
var __delta_offset: Vector3 = Vector3()

var __prev_position: Vector3 = Vector3()
var __delta_pos: Vector3 = Vector3()
var __delta_delta: Vector3 =  Vector3() # __delta_offset - __delta_pos
var __delta_delta_lat: Vector3 =  Vector3() # __delta_delta rotated
var __offset_dir: Vector3 = Vector3() # __prev_offset_position - __prev_position
var __offset_lat: Vector3 = Vector3() # __offset_dir rotated

# How this works:
# - A platform can both move and rotate
# - We have the __offset_node_x "pos.x+=1" tracked position
#     - If platform slides, it's center moves together with __offset_node_x
#     - If platform rotates, only __offset_node_x moves
#     - Any discrepancy between 2 deltas are due to rotation
# 1. Always directly add the central delta
# 2. Extrapolate from offset of 1 to real distance from center
# 3. Account for player direction:
#     - Let's assume __offset_node_x at (1,0,0)
#     - If the player is at (1,0,0) too - they should receive the same delta
#     - If the player is at (2,0,0) - they should receive 2x the delta
#     - If the player is at (-2,0,0) - they should receive -2x the delta
#     - If the player is at (0,0,1) - they should receive 1x the ortho ("lateral") delta
#     - If the player is at (2,0,2) - they should receive 2x delta and lat-delta
# The direction alignment is checked using DOT products
#     - .dot() == 1 - means 2 vectors are in the same direction (from "center")
#     - .dot() == -1 - means 2 vectors look opposite ways
#     - .dot() == 0 - means 2 vectors are orthogonal
# Hence we check against 2 axis in parallel.
#     - The "y" coordinate is ignored.
#     - To obtain orthogonal vector, just swap and add 1 minus: (x, z) -> (z, -x)
func __get_delta_at(pawn_pos: Vector3) -> Vector3:
	var parent: Node3D = get_parent() as Node3D
	if !parent:
		return Vector3()
	
	var parent_offset: Vector3 =  pawn_pos - parent.global_position
	var parent_dist: float =  parent_offset.length()
	var parent_dir: Vector3 = parent_offset / maxf(parent_dist, 0.001)
	
	# How much parent_dir is aligned with __offset_dir and __offset_lat
	var direct_power: float = parent_dir.dot(__offset_dir)
	var lateral_power: float = parent_dir.dot(__offset_lat)
	
	return (
		__delta_pos + # raw position changed
		__delta_delta * parent_dist * direct_power + # primary axis 
		__delta_delta_lat * parent_dist * lateral_power # secondary axis
	)

func _ready() -> void:
	attach()
	
	env_value = { "get_delta_at": __get_delta_at }
	
	var parent: Node = get_parent()
	__offset_node_x = Node3D.new()
	__offset_node_x.position.x += 1
	parent.add_child.call_deferred(__offset_node_x)


func _physics_process(_delta: float) -> void:
	var parent: Node3D = get_parent() as Node3D
	if !parent:
		return
	
	__delta_offset = __offset_node_x.global_position - __prev_offset_position
	__prev_offset_position = __offset_node_x.global_position
	
	__delta_pos = parent.global_position - __prev_position
	__prev_position = parent.global_position
	
	__offset_dir = __prev_offset_position - __prev_position
	__offset_lat = Vector3(__offset_dir.z, __offset_dir.y, -__offset_dir.x)
	__delta_delta =  __delta_offset - __delta_pos
	__delta_delta_lat =  Vector3(__delta_delta.z, __delta_delta.y, -__delta_delta.x)
