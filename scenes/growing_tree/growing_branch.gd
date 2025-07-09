extends Area2D
class_name GrowingBranch

#@export_group("Branch Properties")

@export var param:Resource

## Level of the branch from the tree trunck (0)
@onready var level: int = 0 

## Vector pointing to where the direction the branch is growing
@onready var growth_direction: Vector2 = Vector2.UP
## Vector perpendicular to the branch growing direction
@onready var normal_direction: Vector2  = Vector2(-growth_direction.y, growth_direction.x)

## 1 or -1: changes the sign of the curvature when it goes beyond the maximum absolute angle
@onready var curving_sign: int = 1.

## Array containing the points where a children branch is growing
@onready var branching_points:Array = []
@onready var widths:Array = []

@onready var attach_progress:float = 0

#Color of the branch. Access the polygon shape child color.
@onready var color:Color:
	get():
		return $Shape.color
	set(value):
		$Shape.color = value

## Is the branch still growing ?
var growing:bool = true
var max_width_reached:bool = false
var max_length_reached:bool = false

func _ready():
	randomize()
	param.rand_curve.seed = randi()
	#print(param.rand_curve)
	#add_child(Path2D.new(), true)
	#get_child(0).add_child(PathFollow2D.new(), true)
	
	
	InitializeBranche()

func GetPositionFromProgress(progress:float, width:float = 0) -> Vector2:
	"""Return the local position from the progress along the branch and an orthogonnal offset."""
	$Path2D/PathFollow2D.progress = progress
	$Path2D/PathFollow2D.v_offset = width
	return $Path2D/PathFollow2D.position
	
func GetPositionFromProgressRatio(progress_ratio:float, width:float = 0) -> Vector2:
	"""Returns the local position of the branch at any point along its path.
	progress_ratio -> float in [0, 1]: 0 at the base, 1 at the tip
	width : distance perpendicular to the growth direction
	"""
	$Path2D/PathFollow2D.progress_ratio = progress_ratio
	$Path2D/PathFollow2D.v_offset = width
	return $Path2D/PathFollow2D.position

func GetLength() -> float:
	"""Return length of the branch's path"""
	return $Path2D.curve.get_baked_length()

func GetNbPoints() -> int:
	"""Return the number of points along the branch's path."""
	return $Path2D.curve.point_count


func InitializeBranche():
	"""Initialize the branch. 
	 - Set the growth and normal direction at the base.
	 - Initialize the branch path
	 - Initialize the branch polygon
	"""
	
	## Set growth and normal direction at the base.
	growth_direction = Vector2.from_angle(param.base_angle - PI/2.)
	normal_direction = Vector2(-growth_direction.y, growth_direction.x)
	
	## Init the branch path.
	$Path2D.curve = Curve2D.new()
	$Path2D.curve.add_point(Vector2.ZERO)
	$Path2D.curve.add_point(growth_direction * param.resolution)
	
	## Init the branch polygon
	SetPolygon(PackedVector2Array([
		+ normal_direction * param.min_width/2, 
		+ normal_direction * param.min_width/2 + growth_direction * param.resolution, 
		- normal_direction * param.min_width/2 + growth_direction * param.resolution, 
		- normal_direction * param.min_width/2]))
#	uv = PackedVector2Array([
#		Vector2(1, 0), 
#		Vector2(1, 1), 
#		Vector2(0, 1), 
#		Vector2(0, 0)])
	
func _GetMidIndex(nb_vertices:int)->int:
	"""Returns the index of the vertex at the tip of the branch."""
	return int(nb_vertices / 2.) - 1
	
func GetWidth(index:int) -> float:
	"""Get the width at any point along the branch """
	if len($Shape.polygon) > index and index >= 0:
		return ($Shape.polygon[index] - $Shape.polygon[-1-index]).length()
	else:
		print("ERROR: asked for an index (", index, ") outside of polygon array range.")
		return len($Shape.polygon)

func GrowTip(points:PackedVector2Array, growing_rate:float) -> PackedVector2Array:
	"""Grow the branch at the tip. The branch get longer but not wider."""
	if not growing:
		return points
	
	var nb_vertices:int = len(points)
	var mid_index:int = _GetMidIndex(nb_vertices)
	
	## Check if the maximum length is reached. If true, stop the growth.
	if GetLength() >= param.max_length:
		max_length_reached = true
		growing = false
		print("max length reached")
		return points
	
	## From here, the branch is still growing.
	
	## Adds two points in the polygon at the tip of branch.
	points.insert(mid_index + 1, 	$Shape.polygon[mid_index])
	points.insert(mid_index + 2, 	$Shape.polygon[mid_index+1])
	nb_vertices += 2
	mid_index += 1
	
#	normal_direction = (points[mid_index] - points[mid_index + 1]).normalized()
#	growth_direction = Vector2(normal_direction.y, -normal_direction.x).normalized()
	
	## Curve the branch at the tip and change its growing direction
	var curvature: float = param.rand_curve.get_noise_1d(mid_index) * param.max_curve * curving_sign
	var new_abs_angle:float = fposmod(curvature + growth_direction.angle() + PI/2. + PI, TAU) - PI
	print(rad_to_deg(new_abs_angle),  " ", rad_to_deg(param.max_absolute_angle))
	if new_abs_angle > param.max_absolute_angle or new_abs_angle < - param.max_absolute_angle:
		curving_sign *= -1
		curvature *= curving_sign
		print("too much curbature!", rad_to_deg(new_abs_angle), " ", rad_to_deg(param.max_absolute_angle), " ", rad_to_deg(curvature))
	
	growth_direction = growth_direction.rotated(curvature)
	normal_direction = Vector2.from_angle(curvature + param.base_angle)
	
	## Add point along the path in the new growth direction
	$Path2D.curve.add_point(GetPositionFromProgressRatio(1) + growth_direction * growing_rate)

	## Get the width of the tip of the branch
	var width:float = GetWidth(mid_index + 1)
	
	## Set the position of the new two points of the tip of the branch.
	points[mid_index] 	  = GetPositionFromProgressRatio(1,  width/2.)
	points[mid_index + 1] = GetPositionFromProgressRatio(1, -width/2.)
	
	return points
	
func GrowBranch(points:PackedVector2Array, enlarge_rate:float) -> PackedVector2Array:
	"""Enlarge the branch without elongating it."""
	if not growing:
		return points
	
	var nb_vertices:int = len(points)
	var mid_index:int = _GetMidIndex(nb_vertices)
	
	## Check if the base of the branch has reached maximum width.
	## If true, set growing to false.
	if GetWidth(0) >= param.max_width:
		max_width_reached = true
		growing = false
		print("max_width_reached", param.max_width, " ", GetWidth(0))
	
	## The branch has not reached maximum width
	## Loop over all the points of the Shape polygon and move them to enlarge the branch. 
	## Each vertex width is updated to the previous vertex width.
	for i in range(1, mid_index):
		## Get vertex indices
		var i_R:int = mid_index - i
		var i_L:int = mid_index + 1 + i
		var pi_R:int = mid_index - i - 1
		var pi_L:int = mid_index + i
		
		## Compute normal direction 
		normal_direction = (points[i_R] - points[i_L]).normalized()
		var width = (points[i_R] - points[i_L]).length()
		var pre_width = ($Shape.polygon[pi_R] - $Shape.polygon[pi_L]).length()
		
		if not max_width_reached:
			points[i_R] += normal_direction * (pre_width - width)/2.
			points[i_L] -= normal_direction * (pre_width - width)/2.
		else:
			points[i_R] += (i_R / float(nb_vertices)) * normal_direction * (pre_width - width)/2.
			points[i_L] -= (i_R / float(nb_vertices)) * normal_direction * (pre_width - width)/2.
			
#		if BranchingCondition(enlarge_rate, (points[i] - points[-i-1]).length()):
	
	normal_direction = (points[0] - points[-1]).normalized()
	
	if not max_width_reached:
		points[0]  += normal_direction * enlarge_rate / 2.
		points[-1] -= normal_direction * enlarge_rate / 2.
	
	return points
	
	
func Cut(start:Vector2, end:Vector2):
	"""Cut the branch along a line defined by two points start and end. 
	Everything above that line will be deleted."""
	print(start, end)
	
	#var line = Line2D.new()
	#line.position = Vector2.ZERO - global_position
	#line.default_color = Color(1, 0, 0)
	#line.width = 5
	#line.add_point(start)
	#line.add_point(end)
	#add_child(line) 
	
	
	### Cut the branch polygons (shape and collision)
	
	var polygon:Array = GetPolygon()
	var nb_vertices:int = len(polygon)
	var intersection_points:Array = []
	var intersection_indices:Array = []
	for i in range(1, nb_vertices):
		var branch_start: Vector2 = global_position + polygon[i-1]
		var branch_end:   Vector2 = global_position + polygon[i % nb_vertices]
		
		var intersection = Geometry2D.segment_intersects_segment(start, end, branch_start, branch_end)
		
		#line = Line2D.new()
		#line.default_color = Color(0, 0, 1)
		#line.width = 5
		#line.add_point(branch_start - global_position)
		#line.add_point(branch_end - global_position)
		#add_child(line)
		
		
		if intersection:
			intersection -= global_position
			print("it's a cut!")
			intersection_points.append(intersection)
			intersection_indices.append(i)
			#var circle = Sprite2D.new()
			#circle.texture = load("res://assets/icon.svg")
			#circle.position = intersection
			#add_child(circle)
	
	if len(intersection_points) == 2:
		var new_branch_polygon = polygon.slice(0, intersection_indices[0])
		new_branch_polygon.append(intersection_points[0])
		new_branch_polygon.append(intersection_points[1])
		new_branch_polygon.append_array(polygon.slice(intersection_indices[1]))
		SetPolygon(new_branch_polygon)
		
	### Cut the branch path if necessary
	if len(intersection_points) > 0:
		var path_intersection:Vector2 = Vector2.ZERO
		for i in range(1, GetNbPoints()):
			var branch_start: Vector2 = global_position + $Path2D.curve.get_point_position(i-1)
			var branch_end:   Vector2 = global_position + $Path2D.curve.get_point_position(i)
			
			var intersection = Geometry2D.segment_intersects_segment(start, end, branch_start, branch_end)
		
			if intersection:
				intersection -= global_position
				print("it's a cut!")
				for j in range(i, GetNbPoints()):
					$Path2D.curve.remove_point(i)
				$Path2D.curve.add_point(intersection)
				break
				

func GetPolygon():
	"""Get the shape polygon"""
	return $Shape.polygon

func SetPolygon(new_polygon):
	"""Set the shape polygon"""
	#new_polygon = Geometry2D.decompose_polygon_in_convex(new_polygon)
	$Shape.polygon = new_polygon
	$CollisionShape.polygon = new_polygon
