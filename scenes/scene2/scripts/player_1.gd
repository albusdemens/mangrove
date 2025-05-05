extends RigidBody3D

var move_speed = 20.0
var max_speed = 8.0

func _ready():
	contact_monitor = true
	max_contacts_reported = 10

func _physics_process(_delta):
	# Get input
	var input = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input.z -= 1
	if Input.is_action_pressed("move_backward"): input.z += 1
	if Input.is_action_pressed("move_left"): input.x -= 1
	if Input.is_action_pressed("move_right"): input.x += 1
	
	# Apply force only if not at max speed
	if input != Vector3.ZERO and linear_velocity.length() < max_speed:
		apply_central_force(input.normalized() * move_speed)
	
	# Stop slowly when no input
	if input == Vector3.ZERO:
		linear_velocity = linear_velocity.move_toward(Vector3.ZERO, 0.5)
