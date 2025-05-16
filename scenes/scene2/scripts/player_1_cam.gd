extends Camera3D

@export var target_path: NodePath        # Set this to your player node in the Inspector
@export var offset = Vector3(0, 0.2, -0.4)    # Camera position behind and above player
@export var smooth_speed = 2.0           # Lower = smoother but slower camera
@export var look_ahead = false            # Should camera look ahead of player?

var target: Node3D

func _ready():
	# In scene_2_gameplay.gd, remember to set which camera to use
	#current = true
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if target:
		# Calculate desired position (behind player)
		var target_position = target.global_transform.origin + target.global_transform.basis * offset
		
		# Smoothly move camera to desired position
		global_transform.origin = global_transform.origin.lerp(target_position, smooth_speed * delta)
		
		# Look at player or slightly ahead of player
		if look_ahead:
			look_at(target.global_transform.origin + target.global_transform.basis.z * -2.0)
		else:
			look_at(target.global_transform.origin)

		# Ensure the camera remains fixed relative to the character's vertical position
		global_transform.origin.y = target.global_transform.origin.y + offset.y
