extends GsomPawnHandler


## The body will try to reach this speed.
@export var max_speed: float = 4.0


func _do_physics(pawn: GsomPawn, dt: float) -> void:
	var body := pawn.body as CharacterBody3D
	
	if !pawn.has_action("move"):
		return
	
	var move_target: Vector2 = pawn.get_action("move")
	var diff: Vector2 = move_target - Vector2(body.position.x, body.position.z)
	
	if diff.length_squared() < 0.05:
		pawn.erase_action("move")
	
	var dir: Vector2 = diff.normalized()
	var dxy: Vector2 = dir * dt * max_speed
	
	body.move_and_collide(Vector3(dxy.x, 0.0, dxy.y))
