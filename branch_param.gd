extends Resource
class_name BranchParameters

## Number of vertices in each segment.
@export var resolution:	int 	= 10 

## Maximum length of the branch
@export var max_length:	int 	= 500

@export var min_width: 			int		= 1
@export var max_width: 			int		= 100
@export var width_profile: FastNoiseLite	= FastNoiseLite.new()

## Angle of the branch base with the parent in degree. 0 is parallel, +/-90 perpendicular
@export var base_angle:			float 	= 0. 

@export var rand_curve: FastNoiseLite = FastNoiseLite.new()
## Maximum curvature along the trunk: max angle between two consecutive segments
@export var max_curve: 			float 	= 60.

func _ready():
	rand_curve = FastNoiseLite.new()
	rand_curve.seed = randi()
