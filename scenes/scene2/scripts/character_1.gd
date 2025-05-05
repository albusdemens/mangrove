# Player1.gd
extends RigidBody3D

var total_points = 0
var can_collect_crystals = false  # Player 1 CANNOT collect crystals

func _ready():
	collision_layer = 1  # Players layer
	collision_mask = 7   # Collide with all layers
	lock_rotation = true

func collect_resource(points, is_crystal):
	if is_crystal and not can_collect_crystals:
		print("Player 1 cannot collect crystals!")
		return  # Do nothing
	
	total_points += points
	print("Player 1 collected dandelion! Total: ", total_points)
