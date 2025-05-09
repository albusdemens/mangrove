extends Node3D

# Preload scenes
var seed_scene = preload("res://soil_tile.tscn")
var flower_scene = preload("res://grown_flower_tile.tscn")

# References
@onready var grid_map = $GridMap
@onready var camera = $Camera3D
@onready var overhead_camera = null  # Will be initialized in _ready if it exists
@onready var ui_node = $UI  # Reference to the UI node
# We'll find ResourceCounter dynamically in _ready()
var resource_counter = null

# Game state
var current_mode = "PLACE_SOIL"  # Modes: PLACE_SOIL, PLANT_SEED, COLLECT
var planted_items = {}  # Dictionary to track planted items by position
var points = 0  # Track points (same as coins)

# Camera state
var active_camera_index = 0  # 0 = third person, 1 = overhead
var available_cameras = []

# Recording variables
var is_recording = false
var recording_frames = 0
var max_frames = 600  # 10 seconds at 60fps
var third_person_frames = []
var overhead_frames = []

# Viewport references
var third_person_viewport
var overhead_viewport

func _ready():
	# Find UI node
	ui_node = get_node_or_null("UI")
	if not ui_node:
		print("Error: UI node not found in the scene tree.")
		
	# Try to find ResourceCounter by path or by name in the entire scene tree
	resource_counter = get_node_or_null("UI/ResourceCounter")
	
	# If not found by direct path, search the entire scene tree
	if not resource_counter:
		resource_counter = find_resource_counter(self)
		
	if not resource_counter:
		print("Error: ResourceCounter node not found in scene tree.")
	else:
		print("ResourceCounter found at path: " + str(resource_counter.get_path()))
	
	# Check if player has points already and sync with them
	var player = get_node_or_null("Player1")
	if player:
		# Use player's points as initial value if player exists
		points = player.total_points
		print("DEBUG: Initial sync - Using player points: " + str(points))
	
	# Initialize the points display
	update_points(points)
	
	# Make sure UI is visible if it exists
	if ui_node:
		ui_node.visible = true
		
	# Setup available cameras
	available_cameras.append(camera)  # Add main camera
	
	# Find the overhead camera if it exists
	overhead_camera = get_node_or_null("OverheadCamera")
	if overhead_camera != null:
		available_cameras.append(overhead_camera)
		print("Found OverheadCamera")
	
	# Set only the active camera to current=true
	update_active_camera()
		
	# Setup for recording
	setup_recording_viewports()
	
	# Add input actions
	setup_input_actions()

func setup_input_actions():
	# Add recording toggle action
	if not InputMap.has_action("toggle_recording"):
		InputMap.add_action("toggle_recording")
		var event = InputEventKey.new()
		event.keycode = KEY_R  # Use R key to toggle recording
		InputMap.action_add_event("toggle_recording", event)
		print("Added toggle_recording action to InputMap")
		
	# Add camera switch action
	if not InputMap.has_action("switch_camera"):
		InputMap.add_action("switch_camera")
		var event = InputEventKey.new()
		event.keycode = KEY_C  # Use C key to switch cameras
		InputMap.action_add_event("switch_camera", event)
		print("Added switch_camera action to InputMap")

# Switch to next available camera
func switch_camera():
	if available_cameras.size() <= 1:
		return  # Only one camera, nothing to switch
	
	active_camera_index = (active_camera_index + 1) % available_cameras.size()
	update_active_camera()
	print("Switched to camera: " + available_cameras[active_camera_index].name)

# Update which camera is active for the main viewport
func update_active_camera():
	for i in range(available_cameras.size()):
		available_cameras[i].current = (i == active_camera_index)

# Helper function to recursively find ResourceCounter in scene tree
func find_resource_counter(node):
	# Check if this node has the correct name and is a Label
	if node.get_name() == "ResourceCounter" and node is Label:
		return node
		
	# Recursively check children
	for child in node.get_children():
		var found = find_resource_counter(child)
		if found:
			return found
			
	return null

func setup_recording_viewports():
	# Create viewports for both cameras
	third_person_viewport = SubViewport.new()
	third_person_viewport.size = Vector2(1280, 720)  # HD resolution
	third_person_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	overhead_viewport = SubViewport.new()
	overhead_viewport.size = Vector2(1280, 720)  # HD resolution
	overhead_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Add viewports to the scene
	add_child(third_person_viewport)
	add_child(overhead_viewport)
	
	# Clone cameras for the viewports
	var third_person_cam = $Camera3D.duplicate()
	var overhead_cam = get_node_or_null("OverheadCamera")
	
	if overhead_cam == null:
		print("Warning: OverheadCamera not found. Only recording third-person view.")
	else:
		overhead_cam = overhead_cam.duplicate()
		overhead_viewport.add_child(overhead_cam)
		overhead_cam.current = true
	
	# Add third-person camera to viewport
	third_person_viewport.add_child(third_person_cam)
	third_person_cam.current = true
	
	print("Recording viewports setup complete")

func _process(_delta):
	# Original game logic
	if Input.is_action_just_pressed("plant"):
		handle_click()
	
	# Toggle recording with R key
	if Input.is_action_just_pressed("toggle_recording"):
		toggle_recording()
	
	# Switch camera with C key
	if Input.is_action_just_pressed("switch_camera"):
		switch_camera()
	
	# Record frames if active
	if is_recording:
		record_frame()

func toggle_recording():
	is_recording = !is_recording
	
	if is_recording:
		# Start a new recording
		third_person_frames.clear()
		overhead_frames.clear()
		recording_frames = 0
		print("Recording started")
	else:
		# Save the recorded frames
		save_recordings()
		print("Recording stopped and saved")

func record_frame():
	if recording_frames < max_frames:
		# Capture from both viewports
		var third_person_img = third_person_viewport.get_texture().get_image()
		
		# Store third person view image
		third_person_frames.append(third_person_img)
		
		# If overhead camera exists, capture it too
		if overhead_viewport.get_children().size() > 0:
			var overhead_img = overhead_viewport.get_texture().get_image()
			overhead_frames.append(overhead_img)
		
		recording_frames += 1
		
		# Show recording progress
		if recording_frames % 60 == 0:  # Every second
			print("Recording: " + str(float(recording_frames) / 60) + " seconds")
	else:
		# Max frames reached, stop recording
		toggle_recording()

func save_recordings():
	# Create directories if they don't exist
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("recordings"):
		dir.make_dir("recordings")
	if not dir.dir_exists("recordings/third_person"):
		dir.make_dir("recordings/third_person")
	
	if overhead_frames.size() > 0:
		if not dir.dir_exists("recordings/overhead"):
			dir.make_dir("recordings/overhead")
	
	# Save all frames as PNG files
	print("Saving " + str(recording_frames) + " frames...")
	
	for i in range(recording_frames):
		# Save third-person frame
		third_person_frames[i].save_png("user://recordings/third_person/frame_" + str(i).pad_zeros(5) + ".png")
		
		# Save overhead frame if available
		if i < overhead_frames.size():
			overhead_frames[i].save_png("user://recordings/overhead/frame_" + str(i).pad_zeros(5) + ".png")
		
		# Report progress occasionally
		if i % 60 == 0:
			print("Saved " + str(i) + " frames...")
	
	print("All frames saved to user://recordings/")
	print("Use FFmpeg or similar to convert frames to video")

func handle_click():
	# Get 3D position from mouse click
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		match current_mode:
			"PLACE_SOIL":
				place_soil_at(result.position)
			"PLANT_SEED":
				plant_seed_at(result.position)
			"COLLECT":
				try_collect_at(result.position)

func place_soil_at(world_position):
	# Convert world position to GridMap cell position
	var cell_pos = grid_map.local_to_map(world_position)
	
	# Check if cell is already occupied
	if grid_map.get_cell_item(cell_pos) != -1:
		return
	
	# Place soil tile at cell position
	grid_map.set_cell_item(cell_pos, 0)  # 0 is the item index in your MeshLibrary
	
	# Switch to seed planting mode
	current_mode = "PLANT_SEED"
	print("Soil placed. Now in seed planting mode.")

func plant_seed_at(world_position):
	# Convert world position to GridMap cell position
	var cell_pos = grid_map.local_to_map(world_position)
	
	# Check if there's soil at this position
	if grid_map.get_cell_item(cell_pos) == -1:
		return
	
	# Check if a seed is already planted here
	var cell_key = str(cell_pos)
	if cell_key in planted_items:
		return
	
	# Get world position of the cell center
	var world_pos = grid_map.map_to_local(cell_pos)
	world_pos.y += 0.5  # Offset to place on top of soil
	
	# Instantiate seed
	var seed_instance = seed_scene.instantiate()
	seed_instance.position = world_pos
	add_child(seed_instance)
	
	# Store reference
	planted_items[cell_key] = {
		"object": seed_instance,
		"type": "seed"
	}
	
	# FIRST get current points from player - this is the critical fix
	var player = get_node_or_null("Player1")
	if player:
		# Update our points tracker with player's current total
		points = player.total_points
		print("DEBUG: Synchronized points with player: " + str(points))
		
	# Now deduct 2 points from the properly synchronized value
	print("DEBUG: Before planting seed - Current points: " + str(points))
	points -= 2
	print("DEBUG: After planting seed - Updated points to: " + str(points))
	
	# Update player's counter to match
	if player:
		player.total_points = points
		print("DEBUG: Synced player's total_points to: " + str(points))
	
	# Update UI
	if resource_counter:
		resource_counter.update_coin_count(points)
	
	# Start growth timer
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 15.0
	add_child(timer)
	timer.timeout.connect(func(): grow_flower(cell_key))
	timer.start()
	
	# Switch back to soil placement mode
	current_mode = "PLACE_SOIL"
	print("Seed planted. Back to soil placement mode. Points: " + str(points))

func grow_flower(cell_key):
	# Make sure the seed still exists
	if cell_key in planted_items and planted_items[cell_key]["type"] == "seed":
		# Get the seed position
		var seed_instance = planted_items[cell_key]["object"]
		var pos = seed_instance.position
		
		# Remove the seed
		seed_instance.queue_free()
		
		# Instantiate flower
		var flower_instance = flower_scene.instantiate()
		flower_instance.position = pos
		add_child(flower_instance)
		
		# Connect flower's collected signal
		flower_instance.connect("collected", func(): on_flower_collected(cell_key))
		
		# Update reference
		planted_items[cell_key] = {
			"object": flower_instance,
			"type": "flower"
		}
		
		# Switch to collect mode
		current_mode = "COLLECT"
		print("A flower has grown! Click to collect.")

func try_collect_at(world_position):
	# Convert world position to GridMap cell position
	var cell_pos = grid_map.local_to_map(world_position)
	var cell_key = str(cell_pos)
	
	# Check if there's a flower at this position
	if cell_key in planted_items and planted_items[cell_key]["type"] == "flower":
		# The flower's input_event will handle collection
		# For direct click collection:
		on_flower_collected(cell_key)

func on_flower_collected(cell_key):
	# Remove reference
	planted_items.erase(cell_key)
	
	# Add 10 points when flower is collected
	points += 10
	update_points(points)
	
	# Also update player's total_points to keep systems in sync
	var player = get_node_or_null("Player1")
	if player and player.has_method("collect_resource"):
		player.collect_resource(10, false)  # 10 points for flower, not crystal
	
	# Debug message
	print("DEBUG: Flower collected - Points updated to: " + str(points))
	
	# Switch back to soil placement mode
	current_mode = "PLACE_SOIL"
	print("Flower collected! Back to soil placement mode. Points: " + str(points))

# Renamed function to better reflect what we're tracking
func update_points(new_count: int):
	# Update internal count
	points = new_count
	
	# Update the point count in the UI
	if resource_counter:
		print("DEBUG: Calling resource_counter.update_coin_count(" + str(new_count) + ")")
		resource_counter.update_coin_count(new_count)
		print("DEBUG: After calling update_coin_count. ResourceCounter path: " + str(resource_counter.get_path()))
	else:
		print("ERROR: ResourceCounter is null! Points: " + str(new_count))

# For backward compatibility, maintain this function
func update_coins(new_count: int):
	update_points(new_count)
