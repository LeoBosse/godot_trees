extends Node2D

@export var nb_trees = 10

var tree_scene = preload("res://scenes/growing_tree.tscn")


var positions = []
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	Grow()

func Grow():
	# Grow the forest == several trees
	var screen_size = get_viewport_rect().size
	positions = []
	for i in range(nb_trees):
		positions.append(Vector2((screen_size.x/(nb_trees+1)) * (i+1), screen_size.y-100))
		AddTree(positions[-1], 1)
#		print(get_children()[-1].base_width)

func AddTree(pos:Vector2, scaling:float):
	var tree_instance = tree_scene.instantiate()
	tree_instance.position = pos
	tree_instance.scale = Vector2(1, 1) * scaling
#	tree_instance.material.set_shader_parameter("NOISE_OFFSET", randf())
	add_child(tree_instance)

func _input(_ev):
	if Input.is_action_just_pressed("ui_accept"):
		for t in get_children():
			t.queue_free()
		Grow()
			
