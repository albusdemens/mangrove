extends RigidBody3D

# Adjust this value to control movement speed
@export var move_speed = 10.0

func _physics_process(delta):
	# Get input direction
	var input_vector = Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_vector += Vector3.FORWARD  # Negative Z
	if Input.is_action_pressed("move_backward"):
		input_vector += Vector3.BACK     # Positive Z
	if Input.is_action_pressed("move_left"):
		input_vector += Vector3.LEFT     # Negative X
	if Input.is_action_pressed("move_right"):
		input_vector += Vector3.RIGHT    # Positive X
	
	# Apply force to move the sphere
	if input_vector != Vector3.ZERO:
		input_vector = input_vector.normalized()
		apply_central_force(input_vector * move_speed)
