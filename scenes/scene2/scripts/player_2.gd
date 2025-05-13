extends Node3D

# Define your gem locations
var gem_1_position = Vector3(-0.071, 1.55, 0.95)
var gem_2_position = Vector3(0.845, 1.55, 0.14)

var current_target = 0  # 0 = first gem, 1 = second gem
var movement_speed = 0.35
var score = 0
var target_reached = false

# Movement state
enum MoveState {MOVE_X, MOVE_Z, ARRIVED}
var current_move_state = MoveState.MOVE_X

func _ready():
	print("NPC initialized with specific crystal structure targeting")
	name = "player_2"
	
	# Small delay to ensure scene is fully loaded
	await get_tree().create_timer(0.2).timeout
	print("Starting movement to first crystal at: ", gem_1_position)

func _process(delta):
	# Determine target position
	var target_position = gem_1_position if current_target == 0 else gem_2_position
	
	# Get distance to target
	var distance = global_position.distance_to(target_position)
	
	# Check if we've reached the target
	if distance < 0.1 and not target_reached:
		target_reached = true
		print("Reached target at position: ", target_position)
		
		# Find and collect the crystal at this position
		collect_crystal_at(target_position)
		
		# Wait briefly before moving to next target
		await get_tree().create_timer(0.3).timeout
		
		# Move to next target
		current_target += 1
		current_move_state = MoveState.MOVE_X  # Reset movement state
		target_reached = false  # Reset flag
		
		if current_target > 1:
			print("All targets reached! Final score: ", score)
			set_process(false)  # Stop processing
			return
	
	# Get movement direction based on current state
	var direction = Vector3.ZERO
	
	match current_move_state:
		MoveState.MOVE_X:
			# Move horizontally first
			var x_diff = target_position.x - global_position.x
			
			if abs(x_diff) < 0.05:
				# X alignment achieved, switch to Z movement
				current_move_state = MoveState.MOVE_Z
			else:
				# Move in X direction
				direction.x = sign(x_diff)
		
		MoveState.MOVE_Z:
			# Then move vertically
			var z_diff = target_position.z - global_position.z
			
			if abs(z_diff) < 0.05:
				# Z alignment achieved, we've arrived
				current_move_state = MoveState.ARRIVED
			else:
				# Move in Z direction
				direction.z = sign(z_diff)
		
		MoveState.ARRIVED:
			# We've arrived at the current waypoint
			current_move_state = MoveState.MOVE_X
	
	# Only move if we haven't reached the target
	if not target_reached and direction != Vector3.ZERO:
		global_position += direction.normalized() * movement_speed * delta
	
	# Ensure Y position is locked
	global_position.y = 1.55

# Find and collect a crystal at the specified position
func collect_crystal_at(position):
	print("Searching for crystal at: ", position)
	
	# Find all potential crystals based on their node structure
	var crystals = find_crystals_in_scene()
	print("Found ", crystals.size(), " crystals in scene")
	
	if crystals.size() == 0:
		print("No crystals found in scene!")
		return
	
	# Find the closest crystal to this position
	var closest_crystal = null
	var closest_distance = 3.0  # 3-unit search radius
	
	for crystal in crystals:
		var dist = crystal.global_position.distance_to(position)
		print("Crystal at distance: ", dist, " | Position: ", crystal.global_position)
		
		if dist < closest_distance:
			closest_distance = dist
			closest_crystal = crystal
	
	# If we found a crystal, remove it
	if closest_crystal:
		print("Found crystal to remove: ", closest_crystal.name, " | Distance: ", closest_distance)
		
		# Try to get points if available
		if closest_crystal.get("points") != null:
			score += closest_crystal.points
			print("Added ", closest_crystal.points, " points")
		
		# Remove the crystal
		print("Removing crystal from scene!")
		closest_crystal.queue_free()
		
		# Move to next target
		print("Moving to next target")
		return true
	else:
		print("No crystal found near position: ", position)
		return false

# Find all nodes that match crystal structure: MeshInstance3D with StaticBody3D child
func find_crystals_in_scene():
	var result = []
	var scene_root = get_tree().current_scene
	
	# Get all MeshInstance3D nodes in the scene
	var mesh_instances = get_all_mesh_instances(scene_root)
	
	# Filter to only those with StaticBody3D children
	for mesh in mesh_instances:
		for child in mesh.get_children():
			if child is StaticBody3D:
				# Check if the StaticBody3D has a CollisionShape3D child
				for grandchild in child.get_children():
					if grandchild is CollisionShape3D:
						# This matches our crystal structure!
						result.append(mesh)
						break
				break
	
	return result

# Helper function to get all MeshInstance3D nodes
func get_all_mesh_instances(node):
	var result = []
	
	if node is MeshInstance3D:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(get_all_mesh_instances(child))
	
	return result
