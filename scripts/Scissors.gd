extends Node

var start_position: Vector2 = Vector2(0, 0)
var end_position:   Vector2 = Vector2(0, 0)

var is_cutting: bool = false

signal send_cut(start:Vector2, end:Vector2)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_cutting = true
		start_position = event.position
		var cut_line = Line2D.new()
		cut_line.add_point(start_position)
		cut_line.add_point(start_position)
		add_child(cut_line)
		print("start")
		
		
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		end_position = event.position
		print("end")
		send_cut.emit(start_position, end_position)
		start_position  = Vector2(0, 0)
		end_position    = Vector2(0, 0)
		is_cutting = false
		get_child(0).queue_free()
		
	elif event is InputEventMouseMotion:
		if get_child_count() and is_cutting:
			get_child(0).set_point_position(1, event.position)
		
