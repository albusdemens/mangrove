extends RigidBody3D

var move_speed = 1
var total_points = 0
var can_collect_crystals = false  # Player 1 cannot collect crystals

func _ready():
	contact_monitor = true
	max_contacts_reported = 10
	lock_rotation = true
	# Set collision layers
	collision_layer = 1  # Players layer
	collision_mask = 7   # Collide with all layers

func _physics_process(_delta):  # Fixed: underscore instead of asterisks
	# Get input
	var input = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input.z -= 1
	if Input.is_action_pressed("move_backward"): input.z += 1
	if Input.is_action_pressed("move_left"): input.x -= 1
	if Input.is_action_pressed("move_right"): input.x += 1
	
	# Instant horizontal movement, preserve vertical velocity for gravity
	linear_velocity.x = input.x * move_speed
	linear_velocity.z = input.z * move_speed

# This function is called by the CollectibleResource script
func collect_resource(points, is_crystal):
	# Player 1 cannot collect crystals, only flowers
	if is_crystal:
		print("Player 1 cannot collect crystals!")
		return  # Do nothing with crystals
	
	# Only collect flowers
	total_points += points
	print("Player 1 collected flower! Total points: " + str(total_points))
