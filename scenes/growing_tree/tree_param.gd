@tool
extends Resource
class_name TreeParameters

## Length of a branch segment (in pixels)
@export var growing_rate: float = 50.

## Width added to the branch (in pixels)
@export var enlarge_rate: float = 10.

## Speed of growth, smaller is lower.
@export var grow_frequency: float = 1.

## Choose the branching angle mode to use. \\
## Range: Any angle in intervall [-branching_angle; branching_angle] with respect to level N-1. \\
## Gaussian: Pick an angle following a random gaussian distribution centered on branching_angle with spread angle_spread. \\
## SignedGaussian: Same as Gaussian, but can choose negative angle. (Equivalent to 2 gaussians centred on a and -a). \\
@export_enum("RANGE", "GAUSSIAN", "SIGNED_GAUSSIAN") var branching_mode: String = "SIGNED_GAUSSIAN"
## Maximum angle between the trunk and a branch when branching
@export_range(-180, 180, 5, "radians_as_degrees") var branching_angle: 	float 	= 0
@export_range(0, 360, 1, "radians_as_degrees") var branching_spread: float 	= 0

## Maximum number of level of the tree. the trunk is level 0, first chilf branches level 1, etc...
@export_range(0, 100) var max_levels:	int 	= 1:
	set(new_value):
		max_levels = max(0, new_value)
		if Engine.is_editor_hint():
			branch_max_width_curve.max_domain = max_levels
			branch_len_curve.max_domain = max_levels
			notify_property_list_changed()

## The probability a new branch will grow every second.
@export_range(0, 1, .01) var branching_proba: float = 0.5

## Curve used to define how fast the branches get shorter at every level.
@export var branch_len_curve:Curve = Curve.new()

## Curve used to define how fast the branches get thinner at every level.
@export var branch_max_width_curve:Curve = Curve.new()
