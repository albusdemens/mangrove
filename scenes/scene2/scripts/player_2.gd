extends CharacterBody3D

enum State {IDLE, COLLECT_GEMS, COLLECT_FLOWERS, TRY_RED_FLOWER, FISH_GEM}

@export var move_speed = 3.0
@export var rotation_speed = 5.0
@export var arrival_distance = 0.5

@onready var nav_agent = $NavigationAgent3D

var current_state = State.IDLE
var current_target = null
var targets = {
	"gems": [],
	"flowers": [],
	"red_flower": null,
	"fish_spot": null
}

func _ready():
	# Get all the collectable objects and store them
	var gems = get_tree().get_nodes_in_group("blue_gems")
	var flowers = get_tree().get_nodes_in_group("white_flowers")
	
	# Handle case where groups might be empty with safe fallbacks
	var red_flowers = get_tree().get_nodes_in_group("red_flower")
	var fish_spots = get_tree().get_nodes_in_group("fishing_spot")
	
	targets["gems"] = gems
	targets["flowers"] = flowers
	
	# Use first item or null if not available
	targets["red_flower"] = red_flowers[0] if red_flowers.size() > 0 else null
	targets["fish_spot"] = fish_spots[0] if fish_spots.size() > 0 else null
	
	# Add a custom signal for navigation completion
	if not nav_agent.has_signal("navigation_finished"):
		nav_agent.add_user_signal("navigation_finished")
	
	# Start the state machine
	transition_to(State.COLLECT_GEMS)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			pass
		State.COLLECT_GEMS, State.COLLECT_FLOWERS, State.TRY_RED_FLOWER, State.FISH_GEM:
			navigate_to_target(delta)

func transition_to(new_state):
	current_state = new_state
	
	match new_state:
		State.COLLECT_GEMS:
			if targets["gems"].size() > 0:
				current_target = targets["gems"][0]
				set_navigation_target(current_target.global_position)
			else:
				transition_to(State.COLLECT_FLOWERS)
		State.COLLECT_FLOWERS:
			if targets["flowers"].size() > 0:
				current_target = targets["flowers"][0]
				set_navigation_target(current_target.global_position)
			else:
				transition_to(State.TRY_RED_FLOWER)
		State.TRY_RED_FLOWER:
			current_target = targets["red_flower"]
			set_navigation_target(current_target.global_position)
			# After a delay, simulate failure and move to next state
			await get_tree().create_timer(3.0).timeout
			transition_to(State.FISH_GEM)
		State.FISH_GEM:
			current_target = targets["fish_spot"]
			set_navigation_target(current_target.global_position)
			# Wait until we reach the fishing spot
			await nav_agent.navigation_finished
			# Start fishing
			if current_target.has_method("start_fishing"):
				var success = await current_target.start_fishing(self)
				print("Fishing result: ", "Success" if success else "Failure")
				# Wait a bit before looking for new targets
				await get_tree().create_timer(2.0).timeout
				# Go back to collecting gems (which might include the one we just fished)
				transition_to(State.COLLECT_GEMS)

func set_navigation_target(target_pos):
	nav_agent.set_target_position(target_pos)

func navigate_to_target(delta):
	if nav_agent.is_navigation_finished():
		if current_state == State.COLLECT_GEMS and current_target in targets["gems"]:
			# Remove collected gem
			targets["gems"].erase(current_target)
			current_target.queue_free()
			transition_to(State.COLLECT_GEMS)
		elif current_state == State.COLLECT_FLOWERS and current_target in targets["flowers"]:
			# Remove collected flower
			targets["flowers"].erase(current_target)
			current_target.queue_free()
			transition_to(State.COLLECT_FLOWERS)
		# Emit signal that navigation is finished (for the fishing state)
		nav_agent.emit_signal("navigation_finished")
		return
	
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = (next_path_pos - global_position).normalized()
	
	# Look at the direction we're moving
	if direction:
		var look_direction = direction
		look_direction.y = 0
		if look_direction.length() > 0.01:
			var target_rotation = atan2(look_direction.x, look_direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * rotation_speed)
	
	# Move towards the target
	velocity = direction * move_speed
	move_and_slide()

func collect_item(item):
	# Animation or effect for collecting
	item.queue_free()
