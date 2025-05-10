extends CharacterBody3D

@export var move_speed: float = 2.0
@export var navigation_agent: NavigationAgent3D
@export var target_node_path: NodePath

var target: Node3D

func _ready():
	# Get target node if specified
	if not target_node_path.is_empty():
		target = get_node(target_node_path)
	
	# Otherwise use Player1 as default target
	if target == null:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			target = player
			print("NPC targeting player")
	
	# Configure navigation agent
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 1.0
	
	# Start navigation update cycle
	call_deferred("set_movement_target")

func set_movement_target() -> void:
	if target:
		# Update the navigation path to target
		navigation_agent.target_position = target.global_position
		print("Set new target: ", target.global_position)

func _physics_process(delta):
	if !navigation_agent.is_navigation_finished():
		# Get next position to move to
		var next_position = navigation_agent.get_next_path_position()
		
		# Calculate velocity
		var current_position = global_position
		var new_velocity = (next_position - current_position).normalized() * move_speed
		
		velocity = new_velocity
		move_and_slide()
	
	# Every 2 seconds, update path to target
	if int(Time.get_ticks_msec() / 1000) % 2 == 0:
		set_movement_target()
