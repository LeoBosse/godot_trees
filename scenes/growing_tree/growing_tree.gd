extends Node2D
class_name GrowingTree

@export var param:Resource

@onready var growing_branch_scene:PackedScene = preload("res://scenes/growing_tree/growing_branch.tscn")

## Is the tree still growing? Set to false is none of the branches are still growing.
@onready var growing:bool = true

## Number of branches of the tree. only the trunk at the start.
@onready var nb_branches:int = 1

## Incremented everytime a branch of the tree is growing. goes back to zero on GrowthTimer timeout.
@onready var growing_counter:int = 0

@onready var trunk:Node = %Trunk

func _ready():
	$GrowthTimer.wait_time = param.grow_frequency
	$GrowthTimer.start()

func GrowSubBranches(branch:GrowingBranch) -> void:
	"""Recursive func that grows a branch of the tree and all its children branches.
	branch: the branch to grow with all its childrens."""
	
#	print("grow branch level ", branch.level, level)
	GrowBranch(branch)
	for b in branch.get_children():
		if b is GrowingBranch:
			GrowSubBranches(b)


func GrowBranch(branch:GrowingBranch) -> void:
	"""Grow a branchof the tree."""
	
	if not branch.growing:
		return
	
	growing_counter += 1 # Increment the number of growing branches in the tree.
	var points: PackedVector2Array = branch.GetPolygon()
	## Grow the tip of the branch, making it longer. Adding points to the polygon and the path.
	points = branch.GrowTip(points, param.growing_rate * param.grow_frequency)
	## Enlarge the branch, making it larger but not longer.
	points = branch.GrowBranch(points, param.enlarge_rate * param.grow_frequency)
	branch.SetPolygon(points)
	
	## Add a new child branch if the condition is met.
	if BranchingCondition(branch):
#		print(branch.level, max_levels)
		AddBranch(branch)
	
#	for i in range(0, mid_index+1):
#		print(i, polygon[i], polygon[-1-i])
	
func AddBranch(branch:GrowingBranch) -> void:
	"""Adds a child branch to the branch given in parameter."""
	
	var new_branch:GrowingBranch = growing_branch_scene.instantiate()
	
	## Define the position of the new branch along the existing branch. in [0, 1]
	var new_branch_progress_ratio:float = randf()
	new_branch.position = branch.GetPositionFromProgressRatio(new_branch_progress_ratio)
	new_branch.attach_progress = branch.GetLength() * new_branch_progress_ratio
	
	## Set the new branch parameters based on the parent branch and the tree parameters.
	new_branch.level   = branch.level + 1
	new_branch.z_index = branch.z_index + 1
	
	new_branch.color /= 2

	new_branch.param.setup_local_to_scene()
	
#	new_branch.resolution =  branch.resolution / 2.
	print(param.branch_len_curve.sample(new_branch.level / param.max_levels))
	new_branch.param.max_length =  trunk.param.max_length * param.branch_len_curve.sample(new_branch.level)
	new_branch.param.max_width  =  trunk.param.max_width  * param.branch_max_width_curve.sample(new_branch.level)
	
	#new_branch.rotation = GetBrancheAngle()
	new_branch.param.base_angle = GetBrancheAngle() #new_branch.rotation
	#print(new_branch.base_angle)
	new_branch.param.max_curve = branch.param.max_curve * 1.

	branch.add_child(new_branch)
	nb_branches += 1
	
	print("New branch!")


func BranchingCondition(branch:GrowingBranch) -> bool:
	"""Runs a random computation to decide if we add a banch.
		Conditions : 
			- maximum tree level is not reached (depth of the tree)
			- Number of child branches on a single branch is not reached
			- random throw based on the tree branching proba and the growth frequency
	"""
	var condition:bool = branch.level < param.max_levels \
					 and nb_branches <= branch.param.max_nb_sub_branches \
					 and randf() < param.branching_proba * param.grow_frequency
	return condition
#

func GetBrancheAngle():
	"""Get a new branch angle relative to its parent. Angle is computed based on the branching mode parameter.
		Branching Modes :
			RANGE : The angle is randomly chosen in a uniform range [-a, a]
			GAUSSIAN : The angle is randomly chosen with a gaussian proba density.
			SIGNED_GAUSSIAN : The angle is chosen from a double gaussian proba density, i.e. the sum of one gaussian centered on -a, the other on +a.
	"""
	var angle: float = 0.

	if param.branching_mode == "RANGE":
		angle = GetRANGEBrancheAngle(param.branching_angle)
	elif param.branching_mode == "GAUSSIAN":
		angle = GetGAUSSBrancheAngle(param.branching_angle, param.branching_spread)
	elif param.branching_mode == "SIGNED_GAUSSIAN":
		angle = GetSIGNEDGAUSSBrancheAngle(param.branching_angle, param.branching_spread)
	#print(angle, " angle clamp in range ", param.max_absolute_angle)
	#angle =  clamp(angle, -param.max_absolute_angle, param.max_absolute_angle)
	return angle

func GetRANGEBrancheAngle(max_angle):
	return randf_range(- max_angle, max_angle)
func GetGAUSSBrancheAngle(main, spread):
	return randfn(main, spread)
func GetSIGNEDGAUSSBrancheAngle(main, spread):
	return Array([-1, 1])[randi()%2] * GetGAUSSBrancheAngle(main, spread)


func _on_growth_timer_timeout():
	"""Grow the tree each time the timer runs out (controlled by the grow_frequency parameter)."""
#	print('time to grow!')
	growing_counter = 0 # Reset the number of growing branches to zero
	GrowSubBranches(%Trunk) # Recursively grow all the tree branches strating from the trunk
	if growing_counter == 0: # If no branches have grown, stop the timer and set the tree to not growing
		$GrowthTimer.stop()
		growing = false
	else: # If some branches still grow on this tree, restart the timer.
		$GrowthTimer.start()
