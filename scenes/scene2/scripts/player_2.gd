extends Node3D

# Define your gem locations
var gem_1_position = Vector3(-0.071, 1.55, 0.95)  # Replace with actual position
var gem_2_position = Vector3(0.845, 1.55, 0.14)  # Replace with actual position

var current_target = 0  # 0 = first gem, 1 = second gem
var movement_speed = 0.35
var time_since_start = 0.0

func _ready():
	print("Ultra simple movement script initialized")

func _process(delta):
	time_since_start += delta
	
	# Print debug information
	if int(time_since_start) % 2 == 0:  # Every 2 seconds
		print("Current position: ", global_position, " | Target: ", current_target)
	
	# Determine target position
	var target_position = gem_1_position if current_target == 0 else gem_2_position
	
	# Calculate distance to target
	var distance = global_position.distance_to(target_position)
	print("Distance to target: ", distance)
	
	# Check if we've reached the target
	if distance < 0.05:
		print("Reached target ", current_target)
		# Collect gem logic would go here
		
		# Move to next target
		current_target += 1
		if current_target > 1:
			print("All targets reached")
			set_process(false)  # Stop processing
			return
	
	# Move directly toward target (no physics)
	var direction = (target_position - global_position).normalized()
	global_position += direction * movement_speed * delta
	
	# Ensure Y position is locked
	global_position.y = 1.55
