# Player1.gd
extends RigidBody3D

var total_points = 0
var can_collect_crystals = false  # Player 1 CANNOT collect crystals

func _ready():
	collision_layer = 1  # Players layer
	collision_mask = 7   # Collide with all layers
	lock_rotation = true

func collect_resource(points, is_crystal):
	# Player 1 can ONLY collect flowers, not crystals
	if is_crystal:
		print("Player 1 cannot collect crystals!")
		return  # Exit immediately if it's a crystal
	
	# Only collect flowers/dandelions
	total_points += points  # Add the points from the flower
	print("Player 1 collected flower! Total: ", total_points)
