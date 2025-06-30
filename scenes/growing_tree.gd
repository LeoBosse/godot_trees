extends Node2D
class_name GrowingTree

@export var param:Resource
#
#@export var growing_rate: float = 20.
#@export var enlarge_rate: float = 2.
#
#@export var grow_frequency: float = 0.1:
	#set(value):
		#grow_frequency = value
		#$GrowthTimer.wait_time = value
#
### Maximum angle of a segment with the ground. e.g. PI/2 would prevent any segments to ever go down.
#@export var max_absolute_angle:		float 	= 180
### Choose the branching angle mode to use. \\
### Range: Any angle in intervall [-branching_angle; branching_angle] with respect to level N-1. \\
### Gaussian: Pick an angle following a random gaussian distribution centered on branching_angle with spread angle_spread. \\
### SignedGaussian: Same as Gaussian, but can choose negative angle. (Equivalent to 2 gaussians centred on a and -a). \\
#@export_enum("RANGE", "GAUSSIAN", "SIGNED_GAUSSIAN") var branching_mode: String = "SIGNED_GAUSSIAN"
### Maximum angle between the trunk and a branche when branching
#@export var branching_angle: 		float 	= 0
#@export var branching_spread: 		float 	= 0
#@export var max_levels:				int 	= 5
#
#@export var growth_coeff: float	= 0.7
#@export var width_coeff: float	= 0.7
#
#@export var branching_proba: float = 0.002

@onready var growing_branch_scene:PackedScene = preload("res://scenes/growing_branch.tscn")

@onready var growing:bool = true

@onready var nb_branches:int = 1
@onready var growing_counter:int = 0

var RtoD:float = 180./PI
var DtoR:float = 1. / RtoD

func _ready():
#	growing_branch_scene.resource_local_to_scene = true
#	growing_branch_scene.resource_local_to_scene = true
	$GrowthTimer.start()

func GrowSubBranches(branch:GrowingBranch, level:int) -> void:
#	print("grow branch level ", branch.level, level)
	GrowBranch(branch)
	for b in branch.get_children():
		if b is GrowingBranch:
			GrowSubBranches(b, level + 1)


func GrowBranch(branch:GrowingBranch) -> void:
	if not branch.growing:
		return
	
	growing_counter += 1
	var points: PackedVector2Array = branch.GetPolygon()
	points = branch.GrowTip(points, param.growing_rate * param.grow_frequency)
	points = branch.GrowBranch(points, param.enlarge_rate * param.grow_frequency)
	branch.SetPolygon(points)
	
	if BranchingCondition(branch):
#		print(branch.level, max_levels)
		AddBranch(branch)
	
#	for i in range(0, mid_index+1):
#		print(i, polygon[i], polygon[-1-i])
	
func AddBranch(branch:GrowingBranch) -> void:
	var new_branch:GrowingBranch = growing_branch_scene.instantiate()
	var new_branch_progress_ratio:float = randf()
	
	
	new_branch.position = branch.GetPositionFromProgressRatio(new_branch_progress_ratio)
	new_branch.attach_progress = branch.GetLength() * new_branch_progress_ratio
	
	new_branch.level   = branch.level + 1
	new_branch.z_index = branch.z_index + 1

#	new_branch.resolution =  branch.resolution / 2.
	new_branch.param.max_length =  branch.param.max_length / 1.5
	new_branch.param.max_width  =  branch.GetWidth(int(new_branch.attach_progress / branch.param.resolution))

	#new_branch.rotation = GetBrancheAngle()
	new_branch.param.base_angle = GetBrancheAngle() #new_branch.rotation
	#print(new_branch.base_angle)
	new_branch.param.max_curve = branch.param.max_curve * 1.

	branch.add_child(new_branch)
	nb_branches += 1
	
#	print("New branche!")


func BranchingCondition(branch:GrowingBranch) -> bool:
	var condition:bool = branch.level < param.max_levels \
					 and randf() < param.branching_proba * param.grow_frequency
	return condition
#

func GetBrancheAngle():
	var angle: float = 0.

	if param.branching_mode == "RANGE":
		angle += GetRANGEBrancheAngle(param.branching_angle)
	elif param.branching_mode == "GAUSSIAN":
		angle += GetGAUSSBrancheAngle(param.branching_angle, param.branching_spread)
	elif param.branching_mode == "SIGNED_GAUSSIAN":
		angle += GetSIGNEDGAUSSBrancheAngle(param.branching_angle, param.branching_spread)

	angle =  clamp(angle, -param.max_absolute_angle, param.max_absolute_angle)
	return angle

func GetRANGEBrancheAngle(max_angle):
	return randf_range(- max_angle, max_angle)
func GetGAUSSBrancheAngle(main, spread):
	return randfn(main, spread)
func GetSIGNEDGAUSSBrancheAngle(main, spread):
	return Array([-1, 1])[randi()%2] * GetGAUSSBrancheAngle(main, spread)


func _on_growth_timer_timeout():
#	print('time to grow!')
	growing_counter = 0
	GrowSubBranches(%Trunk, 0)
	if growing_counter == 0:
		$GrowthTimer.stop()
		growing = false
	else:
		$GrowthTimer.start()
