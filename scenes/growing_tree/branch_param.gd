extends Resource
class_name BranchParameters

## Number of vertices in each segment.
@export var resolution:	int 	= 10 

## Maximum length of the branch
@export var max_length:	int 	= 100

@export var min_width: 			int		= 1
@export var max_width: 			int		= 100
@export var width_profile: FastNoiseLite	= FastNoiseLite.new()

## The maximum number of branches growing from this one.
@export var max_nb_sub_branches:int = 10

## Angle of the branch base with the parent in degree. 0 is parallel, +/-90 perpendicular
@export_range(-180, 180, 1, "radians_as_degrees") var base_angle:	float 	= 0. 

## Maximum angle of a segment with the ground. e.g. 90 would prevent any segments to ever go down.
@export_range(0, 180, 1, "radians_as_degrees") var max_absolute_angle:float = 90


## A random noise generator used to curve the branch along its path. Controls wether it is a straight branch or not.
@export var rand_curve: FastNoiseLite = FastNoiseLite.new()


## Maximum curvature along the trunk: max angle between two consecutive segments
@export_range(0, 180, 1, "radians_as_degrees") var max_curve: 	float 	= 60.

func _ready():
	rand_curve = FastNoiseLite.new()
	rand_curve.frequency = 0.0002
	rand_curve.seed = randi()
