@tool
extends MeshInstance2D

var DtoR:float = PI/180.

@export_group("Trunk Properties")
## Number of straight segments in the trunk. Also used as a basis for the number of straight segments in branches
@export var main_segments: 			int 	= 10 
## Length of each straight segment. In pixels.
@export var main_segment_length: 	int 	= 50 
## Width of the trunk on the ground in pixels. Thins as it grows.
@export var main_width: 			int 	= 50 
## Angle of the tree base with the ground. 0 is vertical, +/-PI/2 horizontal
@export var main_angle:				float 	= 0. 
## Maximum curvature along the trunk: max angle between two consecutive segments
@export var main_curve: 			float 	= PI/6
## Origin of the tree
@export var trunk_origin: 			Vector2 = Vector2(0., 0.) 
## Trunk color. 
@export var trunk_color:			Color	= Color(1, .5, .2) 


@export_group("Tree Properties")
## Maximum angle of a segment with the ground. e.g. PI/2 would prevent any segments to ever go down.
@export var max_curve_angle:		float 	= PI/2
## Choose the branching angle mode to use. 
## Range: Any angle in intervall [-branching_angle; branching_angle] with respect to level N-1.
## Gaussian: Pick an angle following a random gaussian distribution centered on branching_angle with spread angle_spread.
## SignedGaussian: Same as Gaussian, but can choose use the negative angle. (Equivalent to 2 gaussians centred on a and -a).
@export_enum("RANGE", "GAUSSIAN", "SIGNED_GAUSSIAN") var branching_mode: String = "RANGE"
@export var relative_branching_angle: bool = true
## Maximum angle between the trunk and a branche when branching
@export var branching_angle: 		float 	= PI/6
@export var branching_spread: 		float 	= PI/18

@export var nb_segments_coeff: float	= 0.7
@export var len_segments_coeff: float	= 0.7
@export var width_coeff: float			= 0.7

@export_group("Leaves Properties")
## Will grow and show the leaves if true.
@export var grow_leaves:			bool	= true
## Allow leaf patches along branches to avoid naked look.
@export var allow_branchless_leaves:bool 	= true 


@onready var _leaf_mesh_instance = $StaticLeaves/Icon
@onready var _leaves = $StaticLeaves

#@onready var dynamic_leaves_emission_mask = $DynamicLeaves/MaskMesh
@onready var _viewport = $DynamicLeaves/SubViewportContainer/SubViewport
@onready var _viewport_container = $DynamicLeaves/SubViewportContainer

var surface_array = []
var dyn_leaves_surface_array = []
var branches_points = []

# PackedVector**Arrays for mesh construction.

#var uvs 	= PackedVector2Array()
#var normals	= PackedVector3Array()
#var indices = PackedInt32Array()


var _noise = FastNoiseLite.new()
#var random = RandomNumberGenerator.new()
#random.randomize()


# Called when the node enters the scene tree for the first time.
func _ready():
	
	surface_array.resize(Mesh.ARRAY_MAX)
	dyn_leaves_surface_array.resize(Mesh.ARRAY_MAX)
	
	material.set_shader_parameter("BASE_COLOR", Vector3(trunk_color.r, trunk_color.g, trunk_color.b))
	$DynamicLeaves.process_material.set_shader_parameter("TREE_SEED", randi())
	
#	MakeTree(main_segments, main_segment_length, main_width, 1, trunk_origin, main_angle, main_curve, trunk_color, 0)
#	GrowLeaves()
#	GrowDynamicLeaves()
	ResetTree()
#	_do_distribution()
	
func MakeTree(nb_segments:int, segment_length:int, base_width:int, min_width:int, segment_origin:Vector2, theta:float, curve:float, color:Color, level:int=0)->void:
#	print("Making tree level ", level)

	var verts 	= PackedVector2Array()
	var colors 	= PackedColorArray()
	var uvs		= PackedVector2Array()
	
	var line_counter: int = 0
	var nb_total_lines: int = nb_segments * segment_length
	var segment_direction: Vector2 = Vector2(sin(theta), -cos(theta))
	var normal_direction: Vector2  = Vector2(-segment_direction.y, segment_direction.x)
	var width: int = base_width
	var to_add_list:Array = []
	
	for s in range(nb_segments):
		for i in range(segment_length):
			width =  GetWidth(base_width, min_width, line_counter, nb_total_lines, level)
			var c = GetColor(color, line_counter)
		
			verts.append(segment_origin + segment_direction * i - normal_direction * width/2)
#			colors.append(Color())
			uvs.append(Vector2(0, float(line_counter)/nb_total_lines))
			verts.append(segment_origin + segment_direction * i + normal_direction * width/2)
#			colors.append(Color(c * .5, 1))
			uvs.append(Vector2(1,  float(line_counter)/nb_total_lines))
			
			line_counter += 1
			
			if BranchingCondition(level, width):
				var branch_angle = GetBrancheAngle(level, theta, branching_angle, max_curve_angle)
				var next_nb_segments = GetNextSegmentNumber(level, nb_segments)
				var next_segment_length = GetNextSegmentLength(level, segment_length)
				var next_width = GetNextWidth(level, width)
#				print("YEA", branch_angle, " ", next_nb_segments, " ", next_segment_length, " ", next_width)
				to_add_list.append([next_nb_segments, next_segment_length, next_width, 1, segment_origin + segment_direction * i, branch_angle, curve, color, level+1])
			
			if LeavesCondition(level, width, base_width):
				# Add random leaves origin along the tree to make denser canopy.
				branches_points.append([verts[-1], level])
		
		
#		delta_theta = randf_range(-curve, curve)
		segment_origin += segment_length * segment_direction
		
		theta = GetSegmentAngle(level, theta, curve, max_curve_angle)
		segment_direction = Vector2(sin(theta), -cos(theta))
		normal_direction  = Vector2(- segment_direction.y, segment_direction.x)
		
	
	for b in to_add_list:
		MakeTree.callv(b)
#		MakeTree(b[0], b[1], b[2], b[3], b[4], b[5], b[6])
		
	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
#	surface_array[Mesh.ARRAY_COLOR]  = colors
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
#	surface_array[Mesh.ARRAY_NORMAL] = normals
#	surface_array[Mesh.ARRAY_INDEX] = indices
	
	# Create mesh surface from mesh array.
	# No blendshapes, lods, or compression used.
#	print("surface_array: ", surface_array)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, surface_array)
	
	branches_points.append([verts[-1], level])
#	print(branches_points)

func GrowDynamicLeaves():
	if not grow_leaves:
		return
		
	
	var b_pos: Vector2
	var level: int
	var screen_size = get_viewport_rect().size
	
#	$DynamicLeaves/SubViewportContainer.size = screen_size
#	viewport.size = screen_size
	var viewport_shift = (Vector2.RIGHT + Vector2.DOWN) * _viewport_container.size * Vector2(.5, 1.)
	$DynamicLeaves.process_material.set_shader_parameter("origin", _viewport_container.position)
	$DynamicLeaves.process_material.set_shader_parameter("tree_size", _viewport_container.size)
#	dynamic_leaves_emission_mask.mesh = ArrayMesh.new()
	for b in range(len(branches_points)):
		b_pos = branches_points[b][0]
		level = branches_points[b][1]
		var patch = $DynamicLeaves/LeavesPatch.duplicate()
		patch.visible = true
		
		patch.position = b_pos + viewport_shift
		patch.scale *= 3. / (level+1)
		_viewport.add_child(patch)
#		dyn_leaves_surface_array = GetLeavesPatch(b_pos, 100)
##		print(dyn_leaves_surface_array)
#		dynamic_leaves_emission_mask.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, dyn_leaves_surface_array)
	
#	var test = MeshTexture.new()
#	test.mesh = dynamic_leaves_emission_mask.mesh
#	var image = Image.load_from_file("res://maple_leaf__83760.png")
#	var test = ImageTexture.create_from_image(image)
#	$DynamicLeaves/Sprite2D.texture = viewport.get_node("SubViewport").get_texture()
	await RenderingServer.frame_post_draw
	print_tree_pretty()
	var mask_texture = _viewport.get_texture()
#	_viewport.get_texture().get_image().save_png("res://Screenshot.png")
#	_viewport_container.visible = true
	$DynamicLeaves.process_material.set_shader_parameter("EMISSION_MASK", mask_texture)
#	_viewport_container.visible = false
	
	
func GetLeavesPatch(origin:Vector2 = Vector2.ONE, size:float = 1.) -> Array:
	var patch = $DynamicLeaves/LeavesPatch
	
	patch.position += origin
	patch.scale *= size
#	var mdt = MeshDataTool.new()
#	mdt.create_from_surface(patch.mesh, 0)
	return patch.mesh.get_mesh_arrays()


func GrowLeaves():
	if not grow_leaves:
		return
	var b_pos: Vector2
	var level: int
	var nb_leaves_per_branches
#	var nb_leaves = 0
	var instance_count = 0
	for b in range(len(branches_points)):
		_leaves.multimesh.instance_count += GetLeavesNumber(branches_points[b][1])
	for b in range(len(branches_points)):
		b_pos = branches_points[b][0]
		level = branches_points[b][1]
		nb_leaves_per_branches = GetLeavesNumber(level)
		for i in range(nb_leaves_per_branches):
			var t = GetLeafTransformation(b_pos)
			_leaves.multimesh.set_instance_transform_2d(instance_count, t)
			instance_count += 1


func ResetTree():
#	randomize()
	mesh = ArrayMesh.new()
#	dynamic_leaves_emission_mask.mesh = ArrayMesh.new()
	_leaves.multimesh = MultiMesh.new()
	_leaves.multimesh.mesh = _leaf_mesh_instance.mesh
	_leaves.multimesh.instance_count = 0
	branches_points = [] 
	
	$DynamicLeaves.Initialize()
	
	print_tree_pretty()  
#	material.set_shader_parameter("NOISE_PATTERN.noise.seed", randi())
#	print(material.get_shader_parameter("NOISE_OFFSET"))
	MakeTree(main_segments, main_segment_length, main_width, 1, trunk_origin, main_angle, main_curve, trunk_color, 0)
	GrowLeaves()
	GrowDynamicLeaves()

func _input(ev):
	if Input.is_action_just_pressed("ui_accept"):
		ResetTree()


func GetWidth(base_width, min_width, dist_from_base, branch_lenght, level):
	var w = float(dist_from_base) * (min_width - base_width) / float(branch_lenght) + base_width
	_noise.frequency = 0.001
	w *= 1 + (_noise.get_noise_1d(dist_from_base) - 0.5) / 4
	return w

func GetColor(base_color, dist_from_base):
	_noise.frequency = 0.5
	return base_color * (_noise.get_noise_1d(dist_from_base) / 2 + .5)

func BranchingCondition(level, width):
	return randf() < 0.005 and width > 1
	
func LeavesCondition(level, width, base_width):
	return allow_branchless_leaves and randf() < 0.002 and width < base_width * .7 and level > 0
	
func GetBrancheAngle(level, trunk_angle, max_curve, max_angle):
	var angle = 0
	if relative_branching_angle:
		angle += trunk_angle
		
	if branching_mode == "RANGE":
		angle += GetRANGEBrancheAngle(level, max_curve)
	elif branching_mode == "GAUSSIAN":
		angle += GetGAUSSBrancheAngle(level, max_curve, branching_spread)
	elif branching_mode == "SIGNED_GAUSSIAN":
		angle += GetSIGNEDGAUSSBrancheAngle(level, max_curve, branching_spread)
	
	angle =  clamp(angle, -max_angle, max_angle)
	return angle

func GetRANGEBrancheAngle(level, max_curve):
	return randf_range(- max_curve, max_curve)
func GetGAUSSBrancheAngle(level, main, spread):
	return randfn(main, spread)
func GetSIGNEDGAUSSBrancheAngle(level, main, spread):
	return Array([-1, 1])[randi()%2] * GetGAUSSBrancheAngle(level, main, spread)


func GetSegmentAngle(level, trunk_angle, max_curve, max_angle):
	return randf_range(max(trunk_angle - max_curve, -max_angle), min(trunk_angle + max_curve, max_angle))

func GetNextSegmentNumber(level, nb_segments):
	return nb_segments * nb_segments_coeff
	
func GetNextSegmentLength(level, segment_length):
	return segment_length * len_segments_coeff
	
func GetNextWidth(level, width):
	return width * width_coeff
	
func GetLeavesNumber(level=0):
	return 100
	
func GetLeafTransformation(branch_pos):
	var dist = abs(randfn(0, 50))
	var angle = randf()*2*PI
	var pos = branch_pos + Vector2(cos(angle), sin(angle)) * dist
	
	var orientation = angle + PI/2
#	var orientation = randf_range(0, 2*PI)
	
	var scaling = Vector2(1, 2)*.1
	
	return Transform2D(orientation, scaling, 0, pos)
	
	
