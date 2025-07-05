extends Area2D

var start_position: Vector2 = Vector2(0, 0)
var end_position:   Vector2 = Vector2(0, 0)

var is_cutting: bool = false

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_cutting = true
		start_position = event.position
		$Line2D.set_point_position(0, start_position)
		$Line2D.set_point_position(1, start_position)
		$CollisionShape2D.shape.a = start_position
		$CollisionShape2D.shape.b = start_position
		
		
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		end_position = event.position
		$Line2D.set_point_position(1, end_position)
		$CollisionShape2D.shape.b = end_position
		
		CutOverlappingBranches()
		
		start_position  = Vector2(0, 0)
		end_position    = Vector2(0, 0)
		is_cutting = false
		
		$Line2D.set_point_position(0, Vector2.ZERO)
		$Line2D.set_point_position(1, Vector2.ZERO)
		$CollisionShape2D.shape.a = Vector2.ZERO
		$CollisionShape2D.shape.b = Vector2.ZERO
		
	elif event is InputEventMouseMotion:
		if get_child_count() and is_cutting:
			$Line2D.set_point_position(1, event.position)
			$CollisionShape2D.shape.b = event.position

func CutOverlappingBranches():
	var overlapping_branches:Array = get_overlapping_areas()
	print("Overlapping branches : ", overlapping_branches)
	
	for b in overlapping_branches:
		b.Cut($CollisionShape2D.shape.a + global_position, $CollisionShape2D.shape.b + global_position)
	
	
