extends Node3D

# Trailer Scene Controller
# This script helps create cinematic sequences for game trailers

# References to camera paths and timeline
var active_camera: Camera3D
var camera_paths = []
var current_sequence = 0
var sequence_timer = 0
var sequence_durations = [5.0, 4.0, 6.0, 5.0] # Duration of each sequence in seconds

# Animation state
var animating = false
var t = 0.0 # Interpolation parameter

func _ready():
	# Set up environment for cinematic quality
	setup_environment()
	
	# Set up the stage with props and lighting
	setup_stage()
	
	# Create camera paths for cinematic shots
	setup_cameras()
	
	# Start the trailer sequence
	start_sequence()
	
	print("Trailer scene initialized and ready for recording!")

func _process(delta):
	# Handle camera animation along paths
	if animating:
		t += delta / sequence_durations[current_sequence]
		if t >= 1.0:
			t = 0.0
			next_sequence()
		else:
			animate_current_camera(t)

func setup_environment():
	# Create high-quality environment for trailer
	var env = WorldEnvironment.new()
	env.name = "CinematicEnvironment"
	
	var environment = Environment.new()
	
	# Cinematic quality settings
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.05)
	
	# Ambient light
	environment.ambient_light_color = Color(0.2, 0.2, 0.3)
	environment.ambient_light_energy = 0.5
	
	# Fog for atmosphere
	environment.fog_enabled = true
	environment.fog_density = 0.02
	environment.fog_aerial_perspective = 0.5
	
	# Glow for cinematic effect
	environment.glow_enabled = true
	environment.glow_intensity = 0.2
	environment.glow_bloom = 0.2
	
	# Depth of field for cinematic shots
	environment.dof_blur_far_enabled = true
	environment.dof_blur_far_distance = 15.0
	environment.dof_blur_far_transition = 5.0
	
	# Assign the environment
	env.environment = environment
	add_child(env)

func setup_stage():
	# Create a visually interesting scene for the trailer
	
	# Ground plane
	var ground = CSGBox3D.new()
	ground.name = "Ground"
	ground.size = Vector3(50, 1, 50)
	ground.position = Vector3(0, -0.5, 0)
	add_child(ground)
	
	# Add some backdrop elements
	create_backdrop()
	
	# Add props for visual interest
	create_props()
	
	# Key lighting for dramatic effect
	create_cinematic_lighting()
	
	# Add game characters or elements
	create_game_elements()

func create_backdrop():
	# Create a backdrop for the scene
	var backdrop = CSGBox3D.new()
	backdrop.name = "Backdrop"
	backdrop.size = Vector3(60, 20, 1)
	backdrop.position = Vector3(0, 9, -20)
	add_child(backdrop)
	
	# Add some mountain-like shapes
	var mountains = [
		{"pos": Vector3(-15, 5, -15), "size": Vector3(10, 12, 8)},
		{"pos": Vector3(-8, 3, -12), "size": Vector3(8, 6, 5)},
		{"pos": Vector3(10, 4, -17), "size": Vector3(12, 8, 10)},
		{"pos": Vector3(20, 6, -14), "size": Vector3(7, 10, 6)}
	]
	
	for i in range(mountains.size()):
		var mountain = CSGBox3D.new()
		mountain.name = "Mountain_" + str(i)
		mountain.size = mountains[i]["size"]
		mountain.position = mountains[i]["pos"]
		# Rotate slightly for interest
		mountain.rotation_degrees = Vector3(0, randf_range(-20, 20), 0)
		add_child(mountain)

func create_props():
	# Create some interesting props for the scene
	var props = [
		{"name": "Pillar_1", "type": "box", "pos": Vector3(-8, 2, 0), "size": Vector3(2, 4, 2)},
		{"name": "Pillar_2", "type": "box", "pos": Vector3(8, 3, 0), "size": Vector3(2, 6, 2)},
		{"name": "Platform", "type": "box", "pos": Vector3(0, 0.5, 0), "size": Vector3(12, 1, 12)},
		{"name": "Arch", "type": "box", "pos": Vector3(0, 5, -5), "size": Vector3(10, 1, 1)},
	]
	
	for prop in props:
		if prop["type"] == "box":
			var box = CSGBox3D.new()
			box.name = prop["name"]
			box.size = prop["size"]
			box.position = prop["pos"]
			add_child(box)

func create_cinematic_lighting():
	# Create dramatic, cinematic lighting
	
	# Main key light (warm)
	var key_light = DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = Vector3(-45, 30, 0)
	key_light.light_color = Color(1.0, 0.9, 0.8)
	key_light.light_energy = 1.5
	key_light.shadow_enabled = true
	add_child(key_light)
	
	# Fill light (cool)
	var fill_light = DirectionalLight3D.new()
	fill_light.name = "FillLight"
	fill_light.rotation_degrees = Vector3(-30, -60, 0)
	fill_light.light_color = Color(0.7, 0.8, 1.0)
	fill_light.light_energy = 0.5
	add_child(fill_light)
	
	# Rim/back light
	var rim_light = DirectionalLight3D.new()
	rim_light.name = "RimLight"
	rim_light.rotation_degrees = Vector3(-20, 180, 0)
	rim_light.light_color = Color(0.9, 0.9, 1.0)
	rim_light.light_energy = 0.7
	add_child(rim_light)
	
	# Add some spotlights for highlights
	var spots = [
		{"pos": Vector3(0, 5, 5), "look_at": Vector3(0, 0, 0), "color": Color(1.0, 0.5, 0.3)},
		{"pos": Vector3(-5, 3, 3), "look_at": Vector3(-3, 0, 0), "color": Color(0.3, 0.5, 1.0)}
	]
	
	for i in range(spots.size()):
		var spot = SpotLight3D.new()
		spot.name = "Spotlight_" + str(i)
		spot.position = spots[i]["pos"]
		spot.look_at_from_position(spots[i]["pos"], spots[i]["look_at"], Vector3.UP)
		spot.light_color = spots[i]["color"]
		spot.light_energy = 2.0
		spot.spot_range = 10.0
		spot.spot_angle = 30.0
		spot.shadow_enabled = true
		add_child(spot)

func create_game_elements():
	# Add main character or game elements for the trailer
	var character = CSGCylinder3D.new()
	character.name = "MainCharacter"
	character.radius = 0.5
	character.height = 2.0
	character.position = Vector3(0, 1, 0)
	add_child(character)
	
	# Add a simple head to the character
	var head = CSGSphere3D.new()
	head.name = "Head"
	head.radius = 0.4
	head.position = Vector3(0, 1.2, 0)
	character.add_child(head)

func setup_cameras():
	# Create multiple camera positions for the trailer
	var camera_setups = [
		{"name": "EstablishingShot", "pos": Vector3(0, 4, 12), "look_at": Vector3(0, 1, 0)},
		{"name": "CloseUpShot", "pos": Vector3(2, 1.7, 3), "look_at": Vector3(0, 1.2, 0)},
		{"name": "DramaticAngle", "pos": Vector3(-4, 2, 4), "look_at": Vector3(0, 0.5, 0)},
		{"name": "WideShot", "pos": Vector3(8, 3, 8), "look_at": Vector3(0, 0, 0)}
	]
	
	for setup in camera_setups:
		var camera = Camera3D.new()
		camera.name = setup["name"]
		camera.position = setup["pos"]
		camera.look_at(setup["look_at"])
		camera.current = false
		
		# Set cinematic camera properties
		camera.fov = 35.0 # More cinematic FOV
		camera.near = 0.1
		camera.far = 100.0
		
		# Store for animation purposes
		camera_paths.append({
			"camera": camera,
			"start_pos": setup["pos"],
			"end_pos": setup["pos"] + Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2)),
			"start_look": setup["look_at"],
			"end_look": setup["look_at"] + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), 0)
		})
		
		add_child(camera)

func start_sequence():
	# Start the trailer sequence
	current_sequence = 0
	sequence_timer = 0
	animating = true
	
	# Set first camera active
	set_active_camera(0)

func next_sequence():
	# Move to the next camera
	current_sequence = (current_sequence + 1) % camera_paths.size()
	set_active_camera(current_sequence)

func set_active_camera(index):
	# Deactivate all cameras
	for path in camera_paths:
		path["camera"].current = false
	
	# Activate the selected camera
	camera_paths[index]["camera"].current = true
	active_camera = camera_paths[index]["camera"]

func animate_current_camera(time_param):
	# Smoothly interpolate camera position and target
	var path = camera_paths[current_sequence]
	
	# Use ease in/out for smoother motion
	var smooth_t = ease(time_param, 2.0) # Smooth easing
	
	# Interpolate camera position
	var new_pos = path["start_pos"].lerp(path["end_pos"], smooth_t)
	path["camera"].position = new_pos
	
	# Interpolate camera target (look_at)
	path["camera"].look_at(path["start_look"].lerp(path["end_look"], smooth_t))

# Add this function to create markers for key trailer moments
func create_sequence_markers():
	var timeline = Node.new()
	timeline.name = "TrailerTimeline"
	
	# Add markers for key moments
	var markers = [
		{"time": 0.0, "name": "Intro"},
		{"time": 5.0, "name": "Character_Reveal"},
		{"time": 9.0, "name": "Action_Moment"},
		{"time": 15.0, "name": "Dramatic_Pause"},
		{"time": 18.0, "name": "Logo_Reveal"}
	]
	
	for marker in markers:
		var marker_node = Node.new()
		marker_node.name = "Marker_" + marker["name"]
		# We would set properties here in a real implementation
		timeline.add_child(marker_node)
	
	add_child(timeline)
