extends Polygon2D

var DtoR:float = PI/180.

@export_group("Tree Properties")
## Maximum angle of a segment with the ground. e.g. PI/2 would prevent any segments to ever go down.
@export var max_absolute_angle:		float 	= PI/2
## Choose the branching angle mode to use. 
## Range: Any angle in intervall [-branching_angle; branching_angle] with respect to level N-1.
## Gaussian: Pick an angle following a random gaussian distribution centered on branching_angle with spread angle_spread.
## SignedGaussian: Same as Gaussian, but can choose use the negative angle. (Equivalent to 2 gaussians centred on a and -a).
@export_enum("RANGE", "GAUSSIAN", "SIGNED_GAUSSIAN") var branching_mode: String = "RANGE"
## Maximum angle between the trunk and a branche when branching
@export var branching_angle: 		float 	= PI/6
@export var branching_spread: 		float 	= PI/18
@export var max_levels:				int 	= 3

@export var nb_segments_coeff: float	= 0.7
@export var len_segments_coeff: float	= 0.7
@export var width_coeff: float			= 0.7


@export_group("Branch Properties")
## Number of straight segments in the branche
@export var nb_segments: 		int 	= 10 
## Length of each straight segment. In pixels.
@export var segment_length: 	int 	= 20 
## Number of vertices in each segment.
@export var nb_vertices_per_segment:	int 	= 5 
## Width of the base of the branch in pixels. Thins as it grows.
@export var base_width: 		int 	= 50 
@export var min_width: 			int		= 1
## Angle of the branch base with the parent. 0 is perpendicular, +/-PI/2 parallel
@export var base_angle:			float 	= 0. 
## Maximum curvature along the trunk: max angle between two consecutive segments
@export var max_curve: 			float 	= PI/6

## Level of the branch from the tree trunck (0)
@onready var level: 			int 	= 0 
@onready var length: float


var _noise = FastNoiseLite.new()
#var random = RandomNumberGenerator.new()
#random.randomize()


# Called when the node enters the scene tree for the first time.
func _ready():
	
	InitializeFromTree()
	length = nb_segments * segment_length
	
	MakeBranch()

func InitializeFromTree():
	
	if level == 0:
		return
	
	nb_segments = GetSegmentNumber()
	## Length of each straight segment. In pixels.
	segment_length = GetSegmentLength()
	## Width of the base of the branch in pixels. Thins as it grows.
	base_width = GetBaseWidth()
	## Angle of the branch base with the parent. 0 is perpendicular, +/-PI/2 parallel
	base_angle += GetBrancheAngle()

	
func MakeBranch():
	var line_counter: int = 0
	var nb_total_lines: int = nb_segments * segment_length
	var curve:float = base_angle
	var segment_origin: Vector2 = Vector2.ZERO
	var segment_direction: Vector2 = Vector2(sin(curve), -cos(curve))
	var normal_direction: Vector2  = Vector2(-segment_direction.y, segment_direction.x)
	var vertices_dist: float = segment_length / float(nb_vertices_per_segment)
	var width: int = base_width

	var vertices: PackedVector2Array = PackedVector2Array()
	var op_vertices: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var op_uvs: PackedVector2Array = PackedVector2Array()
	
	var new_branches: Array = []
	
	
	for s in range(nb_segments):
		var segment_progress:Vector2 = segment_origin
		for i in range(segment_length):
			width =  GetWidth(line_counter)
#			var c = GetColor(line_counter)
		
			segment_progress = segment_origin + segment_direction * i * vertices_dist
#			print(tmp)
			vertices.append(   segment_progress - normal_direction * width/2)
			op_vertices.append(segment_progress + normal_direction * width/2)
#			colors.append(Color())

			uvs.append(   Vector2(0, float(line_counter)/nb_total_lines))
			op_uvs.append(Vector2(1, float(line_counter)/nb_total_lines))
#			colors.append(Color(c * .5, 1))
			
			line_counter += 1
			
			if BranchingCondition(width):
				new_branches.append(duplicate(7))
				new_branches[-1].level += 1
				new_branches[-1].position = segment_progress
				new_branches[-1].SetBaseWidth(width)
				
#			if LeavesCondition(level, width, base_width):
#				# Add random leaves origin along the tree to make denser canopy.
#				branches_points.append([verts[-1], level])
	
		segment_origin = segment_progress
		
		curve = GetSegmentAngle()
		segment_direction = Vector2(sin(curve), -cos(curve))
		normal_direction  = Vector2(- segment_direction.y, segment_direction.x)
	
	
	op_vertices.reverse()
	op_uvs.reverse()
	vertices.append_array(op_vertices)
	uvs.append_array(op_uvs)
	
	polygon = vertices
	uv = uvs
	
	for b in new_branches:
		add_child(b)

func GetWidth(dist_from_base):
	var w = base_width
	w 	 += float(dist_from_base) * (min_width - base_width) / float(length)
	_noise.frequency = 0.001
	w    *= 1 + (_noise.get_noise_1d(dist_from_base) - 0.5) / 4
	return w

func GetColor(dist_from_base):
	_noise.frequency = 0.5
	return color * (_noise.get_noise_1d(dist_from_base) / 2 + .5)

func BranchingCondition(width):
	return level < max_levels and randf() < 0.005 and width > 1.
	
	
func GetBrancheAngle():
	var angle: float = 0.
	
	if branching_mode == "RANGE":
		angle += GetRANGEBrancheAngle(max_absolute_angle)
	elif branching_mode == "GAUSSIAN":
		angle += GetGAUSSBrancheAngle(max_absolute_angle, branching_spread)
	elif branching_mode == "SIGNED_GAUSSIAN":
		angle += GetSIGNEDGAUSSBrancheAngle(max_absolute_angle, branching_spread)
	
	angle =  clamp(angle, -max_absolute_angle, max_absolute_angle)
	return angle

func GetRANGEBrancheAngle(max_angle):
	return randf_range(- max_angle, max_angle)
func GetGAUSSBrancheAngle(main, spread):
	return randfn(main, spread)
func GetSIGNEDGAUSSBrancheAngle(main, spread):
	return Array([-1, 1])[randi()%2] * GetGAUSSBrancheAngle(main, spread)


func GetSegmentAngle():
	return randf_range(max(base_angle - max_curve, -max_absolute_angle), min(base_angle + max_curve, max_absolute_angle))

func GetSegmentNumber():
	return nb_segments * nb_segments_coeff**level
	
func GetSegmentLength():
	return segment_length * len_segments_coeff**level
	
func GetBaseWidth():
	return base_width * width_coeff**level
func SetBaseWidth(parent_width):
	base_width = min(GetBaseWidth(), parent_width) #base_width * width_coeff**level
	
