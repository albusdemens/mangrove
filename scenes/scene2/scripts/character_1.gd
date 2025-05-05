extends CharacterBody3D

var speed = 5.0

func _physics_process(delta):
	# Get input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Apply movement
	velocity.x = input_dir.x * speed
	velocity.z = input_dir.y * speed
	
	# Apply gravity
	velocity.y -= 9.8 * delta
	
	# Move
	move_and_slide()
