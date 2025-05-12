extends CharacterBody3D

@export var gravity = -9.8
@export var speed = 2.0
@export var target_reach_distance = 0.5

@onready var nav_agent = $NavigationAgent3D

var current_target = null

func _ready():
	# Wait for the scene tree to be ready
	await get_tree().process_frame
	
	# Set up the navigation agent
	nav_agent.debug_enabled = true  # Enable path visualization
	
	# Find a valid gem target and move toward it
	find_next_gem_target()

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if not nav_agent.is_navigation_finished():
		# Get the next path position to move toward
		var next_path_position = nav_agent.get_next_path_position()
		
		# Calculate direction to the next path position (keep Y velocity for gravity)
		var y_velocity = velocity.y
		var direction = (next_path_position - global_position).normalized()
		
		# Set velocity (preserve gravity effect)
		velocity = direction * speed
		velocity.y = y_velocity
		
		# Move the character
		move_and_slide()
	elif current_target:
		# Check if we've reached the target
		var distance_to_target = global_position.distance_to(current_target.global_position)
		if distance_to_target < target_reach_distance:
			print("Reached the gem!")
			# Collect the gem
			collect_gem(current_target)
			
					# Find next gem
			find_next_gem_target()

func set_target_location(target_pos):
	nav_agent.target_position = target_pos

func collect_gem(gem):
	# Check if the gem has the CollectibleResource script
	if gem.has_method("collect"):
		gem.collect(self)
	else:
		# If not, just remove it from the scene
		gem.queue_free()
	
	# You could add visual/sound effects here
	print("Gem collected!")

# Method that will be called by CollectibleResource script
func collect_resource(points, is_crystal):
	print("Collected resource: ", points, " points, Crystal: ", is_crystal)
	# You could add score tracking or other functionality here

func find_next_gem_target():
	# Find all gems in the scene
	var gems = get_tree().get_nodes_in_group("blue_gems")
	
	# Find the closest gem
	var closest_gem = null
	var closest_distance = INF
	
	for gem in gems:
		var distance = global_position.distance_to(gem.global_position)
		if distance < closest_distance:
			closest_gem = gem
			closest_distance = distance
	
	# If we found a gem, set it as the target
	if closest_gem != null:
		current_target = closest_gem
		set_target_location(current_target.global_position)
		print("Found new gem target: ", current_target.name)
	else:
		# No more gems to collect
		current_target = null
		print("No gems found to collect!")
