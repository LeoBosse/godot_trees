extends Resource
class_name TreeParameters

## Length of a branch segment (in pixels)
@export var growing_rate: float = 20.

## Width added to the branch (in pixels)
@export var enlarge_rate: float = 2.

@export var grow_frequency: float = .1

## Maximum angle of a segment with the ground. e.g. PI/2 would prevent any segments to ever go down.
@export var max_absolute_angle:float = 180

## Choose the branching angle mode to use. \\
## Range: Any angle in intervall [-branching_angle; branching_angle] with respect to level N-1. \\
## Gaussian: Pick an angle following a random gaussian distribution centered on branching_angle with spread angle_spread. \\
## SignedGaussian: Same as Gaussian, but can choose negative angle. (Equivalent to 2 gaussians centred on a and -a). \\
@export_enum("RANGE", "GAUSSIAN", "SIGNED_GAUSSIAN") var branching_mode: String = "SIGNED_GAUSSIAN"
## Maximum angle between the trunk and a branche when branching
@export var branching_angle: 		float 	= 0
@export var branching_spread: 		float 	= 0
@export var max_levels:				int 	= 5

@export var growth_coeff: float	= 0.7
@export var width_coeff: float	= 0.7

@export var branching_proba: float = 0.5

@export var branch_len_curve:Curve = Curve.new()

#func _ready():
	#branch_len_curve = 
