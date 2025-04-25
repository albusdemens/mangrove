extends CharacterBody3D

# Player movement variables
@export var speed = 5.0
@export var jump_strength = 4.5
@export var mouse_sensitivity = 0.002

# Get the gravity from the project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready():
	# Capture the mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_strength

	# Get input direction
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Transform input direction based on camera orientation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle movement
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Move the character
	move_and_slide()

func _input(event):
	# Handle mouse look
	if event is InputEventMouseMotion:
		# Rotate horizontally
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera vertically
		var camera = $Camera3D
		if camera:
			# Clamp the vertical rotation to avoid flipping
			var current_rotation = camera.rotation.x
			current_rotation -= event.relative.y * mouse_sensitivity
			current_rotation = clamp(current_rotation, -PI/2, PI/2)
			camera.rotation.x = current_rotation
	
	# Handle escape to release mouse
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
