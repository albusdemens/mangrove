extends RigidBody3D

var move_speed = 1
var total_points = 0
var can_collect_crystals = false  # Player 1 cannot collect crystals
var seed_count = 5  # Starting with 5 seeds

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
	
	# Defer the node search until the next frame when we're guaranteed to be in the tree
	call_deferred("_find_planting_manager")

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

func _physics_process(_delta):
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
