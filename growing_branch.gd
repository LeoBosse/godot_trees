extends Polygon2D
class_name GrowingBranch

var DtoR:float = PI/180.

#@export_group("Branch Properties")

@export var param:Resource

## Level of the branch from the tree trunck (0)
@onready var level: 			int 	= 0 

@onready var growth_direction: Vector2 = Vector2.UP
@onready var normal_direction: Vector2  = Vector2(-growth_direction.y, growth_direction.x)

@onready var branching_points:Array = []
@onready var widths:Array = []

@onready var attach_progress:float = 0

var growing:bool = true
var max_width_reached:bool = false
var max_length_reached:bool = false

#var _noise = FastNoiseLite.new()
#var random = RandomNumberGenerator.new()
#random.randomize()

# Called when the node enters the scene tree for the first time.
func _ready():
	param.rand_curve.seed = randi()
	print(param.rand_curve)
	add_child(Path2D.new(), true)
	get_child(0).add_child(PathFollow2D.new(), true)
	get_child(0).curve = Curve2D.new()
	
	InitializeBranche()

func GetPositionFromProgress(progress:float, width:float = 0) -> Vector2:
	$Path2D/PathFollow2D.progress = progress
	$Path2D/PathFollow2D.v_offset = width
	return $Path2D/PathFollow2D.position
	
func GetPositionFromProgressRatio(progress_ratio:float, width:float = 0) -> Vector2:
	$Path2D/PathFollow2D.progress_ratio = progress_ratio
	$Path2D/PathFollow2D.v_offset = width
	return $Path2D/PathFollow2D.position

func GetLength() -> float:
	return $Path2D.curve.get_baked_length()

func GetNbPoints() -> int:
	return $Path2D.curve.point_count



func InitializeBranche():
	
	#print('base_angle ', base_angle)
	growth_direction = Vector2.from_angle(deg_to_rad(param.base_angle - 90))
	normal_direction = Vector2(-growth_direction.y, growth_direction.x)
	
	$Path2D.curve.add_point(Vector2.ZERO)
	$Path2D.curve.add_point(growth_direction * param.resolution)
	
	self.polygon = PackedVector2Array([
		+ normal_direction * param.min_width/2, 
		+ normal_direction * param.min_width/2 + growth_direction * param.resolution, 
		- normal_direction * param.min_width/2 + growth_direction * param.resolution, 
		- normal_direction * param.min_width/2])
#	uv = PackedVector2Array([
#		Vector2(1, 0), 
#		Vector2(1, 1), 
#		Vector2(0, 1), 
#		Vector2(0, 0)])
	
func _GetMidIndex(nb_vertices:int)->int:
	return int(nb_vertices / 2.) - 1
	
func GetWidth(index:int) -> float:
	if len(polygon) > index and index >= 0:
		return (polygon[index] - polygon[-1-index]).length()
	else:
		print("ERROR: asked for an index ", index, "outside of polygon array range.")
		return len(polygon)

func GrowTip(points:PackedVector2Array, growing_rate:float) -> PackedVector2Array:
	
	if not growing:
		return points
	
	var nb_vertices:int = len(points)
	var mid_index:int = _GetMidIndex(nb_vertices)
	
	if float(nb_vertices * growing_rate) / 2 >= param.max_length:
		max_length_reached = true
		growing = false
#		print("max length reached")
		return points
	
	points.insert(mid_index + 1, 	polygon[mid_index])
	points.insert(mid_index + 2, 	polygon[mid_index+1])
	
	var width:float = GetWidth(mid_index + 1)
	
	nb_vertices += 2
	nb_vertices += 2
	mid_index += 1
	
#	normal_direction = (points[mid_index] - points[mid_index + 1]).normalized()
#	growth_direction = Vector2(normal_direction.y, -normal_direction.x).normalized()
	
	var curvature: float = deg_to_rad(param.rand_curve.get_noise_1d(mid_index) * param.max_curve)
	growth_direction = growth_direction.rotated(curvature)
	normal_direction = Vector2.from_angle(curvature + param.base_angle)
	
	$Path2D.curve.add_point(GetPositionFromProgressRatio(1) + growth_direction * growing_rate)

	points[mid_index] 	  = GetPositionFromProgressRatio(1,  width/2.)
	points[mid_index + 1] = GetPositionFromProgressRatio(1, -width/2.)
	
	return points
	
func GrowBranch(points:PackedVector2Array, enlarge_rate:float) -> PackedVector2Array:
	
	if not growing:
		return points
	
	var nb_vertices:int = len(points)
	var mid_index:int = _GetMidIndex(nb_vertices)
	
	if (points[0] - points[-1]).length() >= param.max_width:
		max_width_reached = true
		growing = false
	
	for i in range(1, mid_index):
		
		var i_R:int = mid_index - i
		var i_L:int = mid_index + 1 + i
		var pi_R:int = mid_index - i - 1
		var pi_L:int = mid_index + i
		
		normal_direction = (points[i_R] - points[i_L]).normalized()
		var width = (points[i_R] - points[i_L]).length()
		var pre_width = (polygon[pi_R] - polygon[pi_L]).length()
		
		if not max_width_reached:
			points[i_R] += normal_direction * (pre_width - width)/2.
			points[i_L] -= normal_direction * (pre_width - width)/2.
		else:
			points[i_R] += (i_R / float(nb_vertices)) * normal_direction * (pre_width - width)/2.
			points[i_L] -= (i_R / float(nb_vertices)) * normal_direction * (pre_width - width)/2.
			
#		if BranchingCondition(enlarge_rate, (points[i] - points[-i-1]).length()):
#
#			
	
	normal_direction = (points[0] - points[-1]).normalized()
	
	if not max_width_reached:
		points[0]  += normal_direction * enlarge_rate / 2.
		points[-1] -= normal_direction * enlarge_rate / 2.
	
	return points
	
	
func Cut(start:Vector2, end:Vector2):
	var cut_dir = end - start
	for i in range(1, GetNbPoints()):
		var branch_start: Vector2 = $Path2D.curve.get_point_position(i-1)
		var branch_end:   Vector2 = $Path2D.curve.get_point_position(i)
		var branch_dir = branch_end - branch_start
		print(start, " ", end, " , ", branch_start, " ", branch_end)
		
		var intersection = Geometry2D.line_intersects_line(start, cut_dir, branch_start, branch_dir)
		if intersection:
			print("it's a cut!")
			var circle = Sprite2D.new()
			circle.texture = load("res://assets/icon.svg")
			circle.position = intersection
			add_child(circle)
			
