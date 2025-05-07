extends RigidBody3D

var move_speed = 1
var total_points = 0
var can_collect_crystals = false  # Player 1 cannot collect crystals
var seed_count = 5  # Starting with 5 seeds

# Fishing-related variables
var is_in_fishing_zone = false
var is_fishing = false
var fishing_distance = 20.0  # Maximum fishing distance (increased to reach floor)
var fishing_speed = 2.0  # Speed at which line is cast
var retrieval_speed = 1.0  # Speed at which fish/flowers are retrieved (1/sec as requested)
var current_fishing_depth = 0.0
var fishing_rod
var fishing_line
var rod_tip
var fishing_prompt
var has_fishing_rod_setup = false
var rod_visible = false  # Track rod visibility state
var caught_resource = null  # Reference to caught resource
var is_retrieving = false  # Whether we're bringing up a caught resource
var fishing_bobber = null  # Physics-based bobber at end of line

# States for the fishing process
enum FishingState {
	IDLE,       # Not fishing
	CASTING,    # Line going down
	WAITING,    # Line at bottom waiting for fish
	HOOKED,     # Fish/flower caught
	RETRIEVING  # Bringing up the catch
}
var fishing_state = FishingState.IDLE

func _ready():
	contact_monitor = true
	max_contacts_reported = 10
	lock_rotation = true
	# Set collision layers
	collision_layer = 1  # Players layer
	collision_mask = 7   # Collide with all layers
	# Add to player group so planting manager can find us
	add_to_group("player")
	
	# Debug log to confirm player is ready
	print("Player 1 ready with " + str(seed_count) + " seeds.")
	
	# Find and set fishing prompt
	fishing_prompt = get_node_or_null("/root/scene_2_gameplay/UI/FishingPrompt")
	if not fishing_prompt:
		print("Warning: Fishing prompt UI not found!")
	
	# Defer the node search until the next frame when we're guaranteed to be in the tree
	call_deferred("_find_planting_manager")
	
	# Set up the fishing rod but keep it hidden
	call_deferred("setup_fishing_system")

# Called after _ready via call_deferred to ensure we're in the scene tree
func _find_planting_manager():
	# Find and check the planting manager
	var planting_manager = get_node_or_null("/root/scene_2_gameplay/PlantingManager")
	if planting_manager:
		print("Found PlantingManager")
		
		# Check if flower_scene and dandelion_scene are set correctly
		if planting_manager.has_method("get") and planting_manager.get("flower_scene") != null:
			print("PlantingManager has flower_scene set")
		else:
			print("WARNING: PlantingManager's flower_scene is null!")
			
		if planting_manager.has_method("get") and planting_manager.get("dandelion_scene") != null:
			print("PlantingManager has dandelion_scene set")
		else:
			print("WARNING: PlantingManager's dandelion_scene is null!")
	else:
		print("WARNING: Could not find PlantingManager!")

func _physics_process(delta):
	# Get input
	var input = Vector3.ZERO
	if Input.is_action_pressed("move_forward"): input.z -= 1
	if Input.is_action_pressed("move_backward"): input.z += 1
	if Input.is_action_pressed("move_left"): input.x -= 1
	if Input.is_action_pressed("move_right"): input.x += 1
	
	# Instant horizontal movement, preserve vertical velocity for gravity
	linear_velocity.x = input.x * move_speed
	linear_velocity.z = input.z * move_speed
	
	# Always update the fishing line and rod direction if fishing is active
	if is_fishing and fishing_bobber and fishing_bobber.visible:
		update_fishing_line()
		update_fishing_rod_direction()
	
	# Handle fishing rod visibility and fishing actions
	if has_fishing_rod_setup and fishing_rod != null:
		# Toggle rod visibility when Enter is pressed
		if Input.is_action_just_pressed("ui_accept"):
			rod_visible = !rod_visible
			fishing_rod.visible = rod_visible
			print("Rod visibility toggled to: ", rod_visible)
			
			# If rod is hidden, stop fishing
			if !rod_visible and is_fishing:
				stop_fishing()
		
		# Cast fishing line with right mouse button when rod is visible
		if rod_visible and Input.is_action_just_pressed("fish_line"):  # Using our new fish_cast input action
			if fishing_state == FishingState.IDLE:
				start_fishing()
			else:
				# If already fishing, right-click will reel in the line
				retract_fishing_line()
	
	# Update fishing if active
	if is_fishing:
		update_fishing(delta)

# This function is called by the CollectibleResource script
func collect_resource(points, is_crystal):
	# Player 1 cannot collect crystals, only flowers
	if is_crystal:
		print("Player 1 cannot collect crystals!")
		return  # Do nothing with crystals
	
	# Only collect flowers
	total_points += points
	seed_count += 1  # Get one seed when collecting a dandelion
	print("Player 1 collected flower! Total points: " + str(total_points) + ", Seeds: " + str(seed_count))

# Called by the planting manager when using a seed
func use_seed_for_planting():
	if seed_count > 0:
		seed_count -= 1
		print("Used a seed for planting. Remaining seeds: " + str(seed_count))
		return true
	else:
		print("Not enough seeds!")
		return false

# Called by the planting manager when using a flower
func use_flower_for_planting():
	# We could implement this if flowers can be planted
	pass

# Fishing system setup function
func setup_fishing_system():
	# Get the existing fishing rod that's already in the scene
	fishing_rod = $FishingRod
	if fishing_rod == null:
		print("ERROR: Couldn't find the FishingRod node!")
		return
		
	# Get the rod tip marker node
	rod_tip = fishing_rod.get_node("RodTip")
	if rod_tip == null:
		print("ERROR: Couldn't find the RodTip node!")
		return
		
	# Create fishing line if it doesn't exist
	fishing_line = rod_tip.get_node_or_null("FishingLine")
	if fishing_line == null:
		fishing_line = MeshInstance3D.new()
		fishing_line.name = "FishingLine"
		rod_tip.add_child(fishing_line)
	
	# Create fishing bobber if it doesn't exist
	fishing_bobber = rod_tip.get_node_or_null("FishingBobber")
	if fishing_bobber == null:
		# Create a RigidBody3D for the bobber with physics
		fishing_bobber = RigidBody3D.new()
		fishing_bobber.name = "FishingBobber"
		fishing_bobber.gravity_scale = 6.0  # Make it even heavier for faster, straighter descent
		fishing_bobber.mass = 3.0  # Add more mass to fall straighter
		fishing_bobber.linear_damp = 1.0  # Less damping for faster movement
		fishing_bobber.lock_rotation = true  # Prevent rotation
		fishing_bobber.collision_layer = 2  # Put bobber in its own layer (was 0)
		fishing_bobber.collision_mask = 7   # Detect collisions with layers 1, 2, and 3 (was 1)
		fishing_bobber.contact_monitor = true  # Enable collision monitoring
		fishing_bobber.max_contacts_reported = 4  # Report up to 4 collisions
		fishing_bobber.continuous_cd = true  # Enable continuous collision detection (previously using constant)
		get_tree().root.add_child(fishing_bobber)  # Add to root to make physics work properly
		
		# Connect the collision signal
		fishing_bobber.body_entered.connect(_on_bobber_body_entered)
		
		# Add mesh to visualize the bobber
		var bobber_mesh = MeshInstance3D.new()
		bobber_mesh.name = "BobberMesh"
		fishing_bobber.add_child(bobber_mesh)
		
		# Create sphere mesh for the bobber - MUCH smaller now (1/10 size)
		var sphere = SphereMesh.new()
		sphere.radius = 0.02  # 1/10 the previous size
		sphere.height = 0.04
		bobber_mesh.mesh = sphere
		
		# Add material to the bobber - brighter color for better visibility
		var bobber_material = StandardMaterial3D.new()
		bobber_material.albedo_color = Color(1.0, 0.0, 0.0)  # Bright red color
		bobber_material.emission_enabled = true  # Make it glow
		bobber_material.emission = Color(1.0, 0.0, 0.0, 0.8)
		bobber_material.emission_energy = 0.5
		bobber_mesh.material_override = bobber_material
		
		# Add collision shape - keep collision shape a bit larger than visual
		var collision = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.05  # Collision slightly larger than visual
		collision.shape = sphere_shape
		fishing_bobber.add_child(collision)
		
		# Make it initially invisible
		fishing_bobber.visible = false
	
	# Make sure rod is hidden initially
	fishing_rod.visible = false
	rod_visible = false
	
	has_fishing_rod_setup = true
	print("Fishing system set up successfully! Using existing FishingRod from scene.")

# Update fishing line visual to connect rod tip to bobber with proper physics
func update_fishing_line():
	if !fishing_bobber || !rod_tip || !fishing_bobber.visible:
		return
		
	# Clear any existing mesh
	var line_mesh = ImmediateMesh.new()
	
	# Create material if needed
	if not fishing_line.material_override:
		var line_material = StandardMaterial3D.new()
		line_material.albedo_color = Color(1.0, 1.0, 1.0)  # Pure white for visibility
		line_material.emission_enabled = true  # Make it glow
		line_material.emission = Color(1.0, 1.0, 1.0, 0.8)
		line_material.emission_energy = 0.5
		line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fishing_line.material_override = line_material
	
	# Use a simpler approach - just draw a single line from rod tip to bobber
	line_mesh.clear_surfaces()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Convert bobber position to local space of rod_tip
	var bobber_local_pos = rod_tip.global_transform.inverse() * fishing_bobber.global_transform.origin
	
	# Add line vertices - from tip (local origin) to bobber (in rod_tip's local space)
	line_mesh.surface_set_color(Color(1, 1, 1))
	line_mesh.surface_add_vertex(Vector3.ZERO)  # Rod tip position (local origin)
	line_mesh.surface_add_vertex(bobber_local_pos)  # Bobber position in local space
	
	line_mesh.surface_end()
	
	# Apply mesh
	fishing_line.mesh = line_mesh
	
	# Print debugging info
	print("Rod tip global position: ", rod_tip.global_position)
	print("Bobber global position: ", fishing_bobber.global_position)
	print("Bobber local position: ", bobber_local_pos)

# Make fishing rod point toward the bobber
func update_fishing_rod_direction():
	if !fishing_bobber || !fishing_rod:
		return
	
	# Don't rotate the fishing rod - keep its original orientation relative to player
	# We only need to update the line
	pass  # Rod stays in fixed position attached to player

# Called when player enters a fishing zone
func enter_fishing_zone():
	is_in_fishing_zone = true
	if fishing_prompt:
		fishing_prompt.visible = true
	print("Entered fishing zone")

# Called when player exits a fishing zone
func exit_fishing_zone():
	is_in_fishing_zone = false
	if fishing_prompt:
		fishing_prompt.visible = false
	
	if is_fishing:
		stop_fishing()
	print("Exited fishing zone")

# Start fishing action
func start_fishing():
	is_fishing = true
	current_fishing_depth = 0.0
	fishing_state = FishingState.CASTING
	caught_resource = null
	is_retrieving = false
	
	# Make sure rod is visible when fishing
	if has_fishing_rod_setup and fishing_rod != null:
		rod_visible = true
		fishing_rod.visible = true
		
		# Initialize bobber position at rod tip
		if fishing_bobber:
			fishing_bobber.visible = true
			# Set position at rod tip
			fishing_bobber.global_position = rod_tip.global_position
			# Reset all velocity
			fishing_bobber.linear_velocity = Vector3.ZERO
			# Ensure the bobber is directly below the rod tip in the XZ plane
			fishing_bobber.global_position.x = rod_tip.global_position.x
			fishing_bobber.global_position.z = rod_tip.global_position.z
			
			# Create/update the fishing line immediately
			update_fishing_line()
	
	if fishing_prompt:
		fishing_prompt.visible = false
		
	print("Started fishing! Rod visibility: ", fishing_rod.visible)

# Update fishing state each frame
func update_fishing(_delta):
	match fishing_state:
		FishingState.CASTING:
			# Apply downward force to bobber to simulate casting
			if fishing_bobber:
				if current_fishing_depth < fishing_distance:
					 # Only apply force in the Y direction (downward) to ensure vertical movement
					fishing_bobber.linear_velocity.x = 0
					fishing_bobber.linear_velocity.z = 0
					fishing_bobber.apply_central_force(Vector3(0, -60.0, 0))
					current_fishing_depth = rod_tip.global_position.distance_to(fishing_bobber.global_position)
					
					# Update line to connect rod tip and bobber
					update_fishing_line()
					
					# Check for collisions at bobber position
					check_for_collisions(fishing_bobber.global_position)
				else:
					# Reached maximum distance, switch to waiting state
					fishing_state = FishingState.WAITING
					print("Line fully extended, waiting for fish...")
			
		FishingState.WAITING:
			# Keep the line extended, periodically check for fish
			if fishing_bobber:
				 # Zero out horizontal movement, maintain vertical forces
				fishing_bobber.linear_velocity.x = 0
				fishing_bobber.linear_velocity.z = 0
				
				# Apply small downward force to keep bobber down
				fishing_bobber.apply_central_force(Vector3(0, -5.0, 0))
				
				# Update line visual to follow bobber
				update_fishing_line()
				check_for_collisions(fishing_bobber.global_position)
			
		FishingState.HOOKED:
			# Switch to retrieving state and start animation
			fishing_state = FishingState.RETRIEVING
			retrieve_catch()
			
		FishingState.RETRIEVING:
			# Gradual retrieval is handled by the tween in retrieve_catch()
			if fishing_bobber:
				update_fishing_line()

# Check for collisions with floor and fishable resources
func check_for_collisions(target_position):
	# Create physics query
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		rod_tip.global_position,
		target_position
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		if result.collider.is_in_group("fishable_resource"):
			print("Found fishable resource!")
			caught_resource = result.collider
			fishing_state = FishingState.HOOKED
		elif fishing_state == FishingState.CASTING:
			# Hit something (like the floor) while casting
			print("Line hit something (floor or object).")
			fishing_state = FishingState.WAITING
			current_fishing_depth = rod_tip.global_position.distance_to(result.position)
			
			# Stop bobber movement at collision point
			if fishing_bobber:
				fishing_bobber.linear_velocity = Vector3.ZERO
				fishing_bobber.global_position = result.position
				update_fishing_line()

# Called when the bobber collides with another physics body
func _on_bobber_body_entered(body):
	print("Bobber collided with: ", body.name)
	
	# Stop the bobber's movement when it hits a physical object
	if fishing_state == FishingState.CASTING:
		fishing_state = FishingState.WAITING
		fishing_bobber.linear_velocity = Vector3.ZERO
		
		# Apply a small bounce effect
		fishing_bobber.apply_central_impulse(Vector3(0, 1.0, 0))
		
		# Keep the bobber at its current position
		current_fishing_depth = rod_tip.global_position.distance_to(fishing_bobber.global_position)
		
		print("Bobber stopped at collision with: ", body.name)
	
	# Check if the object is a fishable flower
	var parent = body.get_parent()
	if parent and (parent.is_in_group("fishable_resource") or (parent.get_parent() and parent.get_parent().is_in_group("fishable_resource"))):
		# Find the actual collectible node
		var collectible = parent
		if parent.get_parent() and parent.get_parent().is_in_group("fishable_resource"):
			collectible = parent.get_parent()
		
		print("Bobber hit a fishable resource: ", collectible.name)
		
		# Set the caught resource and change state to HOOKED
		caught_resource = collectible
		fishing_state = FishingState.HOOKED
		
		# Start retrieving the caught resource
		retrieve_catch()
	elif body.is_in_group("fishable_resource"):
		caught_resource = body
		fishing_state = FishingState.HOOKED
		print("Hooked a fishable resource: ", body.name)
		retrieve_catch()

# Retrieve the caught resource with a slow animation
func retrieve_catch():
	if caught_resource:
		print("Retrieving the catch!")
		
		# Create a tween to animate retrieval at 1 unit per second
		var tween = create_tween().set_ease(Tween.EASE_OUT)
		
		# Calculate starting position and distance
		var start_pos = fishing_bobber.global_position
		var end_pos = rod_tip.global_position
		var distance = start_pos.distance_to(end_pos)
		
		# Calculate how long retrieval should take at retrieval_speed
		var retrieval_time = distance / retrieval_speed
		
		# Function to update bobber position during retrieval
		var update_bobber_pos = func(t: float):
			if fishing_bobber and is_instance_valid(fishing_bobber):
				# Calculate intermediate position
				var intermediate_pos = start_pos.lerp(end_pos, t)
				
				# Maintain the rod tip's XZ position to ensure vertical alignment
				intermediate_pos.x = rod_tip.global_position.x
				intermediate_pos.z = rod_tip.global_position.z
				
				# Apply the position
				fishing_bobber.global_position = intermediate_pos
				update_fishing_line()
		
		# Animate bobber movement
		tween.tween_method(update_bobber_pos, 0.0, 1.0, retrieval_time)
		
		# Move caught resource along with the bobber
		if caught_resource:
			var resource_start_pos = caught_resource.global_position
			
			# Function to update resource position during retrieval
			var update_resource_pos = func(t: float):
				if is_instance_valid(caught_resource):
					caught_resource.global_position = resource_start_pos.lerp(end_pos, t)
			
			# Add another track to move the resource
			tween.parallel().tween_method(update_resource_pos, 0.0, 1.0, retrieval_time)
		
		# When complete, collect the resource and reset
		tween.tween_callback(Callable(self, "_finish_collection"))

# Called when retrieval animation finishes
func _finish_collection():
	if is_instance_valid(caught_resource):
		# Collect the resource
		if caught_resource.has_method("collect"):
			caught_resource.collect(self)
		else:
			collect_fishable_resource(caught_resource)
	
	# Reset fishing state
	fishing_state = FishingState.IDLE
	caught_resource = null
	is_retrieving = false
	stop_fishing()

# Collect a resource caught with fishing rod
func collect_fishable_resource(resource):
	print("Caught a resource with fishing rod!")
	
	# Use your existing collection logic
	if resource.has_method("collect"):
		resource.collect(self)
	else:
		# Fallback direct collection
		seed_count += 1
		print("Fished a resource! Seeds: " + str(seed_count))
		
		# Remove the resource
		resource.queue_free()

# Retract fishing line animation
func retract_fishing_line():
	if fishing_state == FishingState.RETRIEVING:
		return # Don't interrupt an ongoing retrieval
		
	# Create a tween to animate line retraction
	var tween = create_tween()
	
	# Start and end positions
	var start_pos = fishing_bobber.global_position
	var end_pos = rod_tip.global_position
	
	# Function to update bobber position during retraction
	var update_bobber_pos = func(t: float):
		if fishing_bobber and is_instance_valid(fishing_bobber):
			# Calculate intermediate position
			var intermediate_pos = start_pos.lerp(end_pos, t)
			
			# Maintain the rod tip's XZ position for vertical alignment
			intermediate_pos.x = rod_tip.global_position.x
			intermediate_pos.z = rod_tip.global_position.z
			
			fishing_bobber.global_position = intermediate_pos
			update_fishing_line()
			update_fishing_rod_direction()  # Update rod direction to follow bobber
	
	# Animate bobber movement (faster than regular retrieval)
	tween.tween_method(update_bobber_pos, 0.0, 1.0, 0.5)
	tween.tween_callback(Callable(self, "stop_fishing"))

# Stop fishing and clean up
func stop_fishing():
	is_fishing = false
	fishing_state = FishingState.IDLE
	
	# Hide bobber
	if fishing_bobber:
		fishing_bobber.visible = false
	
	# Clear fishing line
	if fishing_line and fishing_line.mesh:
		fishing_line.mesh.clear_surfaces()
	
	# Show prompt if still in zone
	if is_in_fishing_zone and fishing_prompt:
		fishing_prompt.visible = true
		
	print("Stopped fishing! Rod visibility remains: ", fishing_rod.visible)
