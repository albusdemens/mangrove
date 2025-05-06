# PlantingManager.gd
extends Node3D

@export var grid_size: float = 1.0  # Size of each grid cell
@export var planting_height: float = 0.5  # Height for planting indicator
@export var flower_scene: PackedScene  # Reference to your flower scene
@export var dandelion_scene: PackedScene  # Reference to dandelion scene (same as flower_scene if not set)

var camera: Camera3D
var selected_cell: Vector3i = Vector3i(-999, -999, -999)  # Invalid position
var can_plant: bool = false
var plant_indicator: MeshInstance3D
var current_player: int = 1  # Default to player 1
var planting_on_box: bool = false  # Tracks whether planting on ground or box

func _ready():
	# Create planting indicator (a colored square)
	plant_indicator = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(grid_size, grid_size)
	plant_indicator.mesh = quad_mesh
	
	# Create material for the indicator
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 0, 0.5)  # Semi-transparent green
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plant_indicator.material_override = mat
	plant_indicator.visible = false
	add_child(plant_indicator)
	
	# Get camera reference
	camera = get_viewport().get_camera_3d()
	
	# Try to load the flower scene if it's not set in the editor
	if flower_scene == null:
		var flower_path = "res://scenes/scene2/grown_flower_tile.tscn"
		if ResourceLoader.exists(flower_path):
			flower_scene = load(flower_path)
			print("Successfully loaded flower_scene from: " + flower_path)
			# Use the same scene for dandelions if not set
			if dandelion_scene == null:
				dandelion_scene = flower_scene
		else:
			print("WARNING: Could not find flower scene at: " + flower_path)
	
	print("PlantingManager _ready() - Creating programmatic objects as fallback")
	print("Current script path: " + get_script().resource_path)
	
	# Only create programmatic objects if we still don't have flower scenes
	if flower_scene == null:
		# Create all resources programmatically to avoid path issues
		var dandelion = Node3D.new()
		dandelion.name = "CollectibleDandelion"
		
		# Try to load the dandelion mesh
		var dandelion_mesh = null
		var mesh_paths = [
			"res://assets/dandelions.obj",
			"res://scenes/scene2/assets/dandelions.obj",
			"res://assets/scene2/dandelions.obj"
		]
		
		# First check which paths exist
		for path in mesh_paths:
			print("Checking if path exists: " + path)
			if FileAccess.file_exists(path):
				print("Found file at: " + path)
				dandelion_mesh = load(path)
				if dandelion_mesh != null:
					print("Successfully loaded dandelion mesh")
					break
		
		if dandelion_mesh == null:
			print("Could not load dandelion mesh, will use placeholder")
			
		# Create a simple mesh instance
		var mesh_instance = MeshInstance3D.new()
		if dandelion_mesh != null:
			mesh_instance.mesh = dandelion_mesh
		else:
			# Use a simple cube if we can't load the dandelion
			var cube_mesh = BoxMesh.new()
			cube_mesh.size = Vector3(0.2, 0.2, 0.2)
			mesh_instance.mesh = cube_mesh
		
		dandelion.add_child(mesh_instance)
		
		# Now create the collectible behavior directly
		dandelion.set_meta("points", 10)
		dandelion.set_meta("is_crystal", false)
		
		# Create an Area3D for collection
		var area = Area3D.new()
		var collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.2, 0.2, 0.2)
		collision_shape.shape = shape
		
		area.add_child(collision_shape)
		area.collision_layer = 2  # Resources layer
		area.collision_mask = 1   # Players layer
		dandelion.add_child(area)
		
		 # Define collection behavior right here
		area.body_entered.connect(func(body):
			if body.has_method("collect_resource"):
				body.collect_resource(dandelion.get_meta("points", 10), dandelion.get_meta("is_crystal", false))
				dandelion.queue_free()
		)
		
		# Create the flower_scene
		var simple_scene = PackedScene.new()
		var result = simple_scene.pack(dandelion)
		if result == OK:
			print("Successfully created the programmatic dandelion scene")
			flower_scene = simple_scene
			dandelion_scene = simple_scene
		else:
			print("Failed to create the programmatic scene, error: " + str(result))
			
	print("Flower scene status: " + ("Available" if flower_scene != null else "Unavailable"))
	print("Dandelion scene status: " + ("Available" if dandelion_scene != null else "Unavailable"))

func _process(_delta):
	if camera:
		update_planting_position()
		
		# Plant when clicking
		if Input.is_action_just_pressed("plant") and can_plant:
			if planting_on_box:
				plant_seed_on_box()
			else:
				plant_flower()

func update_planting_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Raycast to find ground or boxes
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4 | 1  # Environment layer and player collision objects
	var result = space_state.intersect_ray(query)
	
	if result:
		# Check if this is a box/platform (by checking height or collision layer)
		var is_box = result.position.y > 0.1  # Simple height check, adjust as needed
		planting_on_box = is_box
		
		 # Get the actual clicked position
		var world_pos = result.position
		
		# Snap to grid
		var grid_pos = Vector3i(
			round(world_pos.x / grid_size),
			round(world_pos.y / grid_size) if is_box else 0,  # Keep on ground level or box level
			round(world_pos.z / grid_size)
		)
		
		selected_cell = grid_pos
		
		# Check if position is valid
		can_plant = is_valid_planting_spot(grid_pos)
		
		# Update indicator position to show exactly where the plant will appear
		plant_indicator.position = Vector3(
			grid_pos.x * grid_size,
			grid_pos.y * grid_size + (0.01 if is_box else planting_height), # Slightly above the box or at planting height
			grid_pos.z * grid_size
		)
		
		# Rotate indicator based on planting surface
		if is_box:
			plant_indicator.rotation_degrees = Vector3(90, 0, 0)  # Lay flat on top
		else:
			plant_indicator.rotation_degrees = Vector3(0, 0, 0)  # Default orientation
			
		plant_indicator.visible = true
		
		# Change color based on validity
		var mat = plant_indicator.material_override as StandardMaterial3D
		if can_plant:
			# Indicate which player is planting with color
			if current_player == 1:
				mat.albedo_color = Color(1, 0, 0, 0.5)  # Red for player 1
			else:
				mat.albedo_color = Color(0, 1, 0, 0.5)  # Green for player 2
		else:
			mat.albedo_color = Color(0.5, 0.5, 0.5, 0.5)  # Gray if invalid
	else:
		plant_indicator.visible = false

# Set the current player who is planting
func set_player(player_number: int):
	current_player = player_number

func is_valid_planting_spot(grid_pos: Vector3i) -> bool:
	# Check if there's already something at this position
	var world_pos = Vector3(grid_pos.x * grid_size, grid_pos.y * grid_size, grid_pos.z * grid_size)
	
	# Check for existing objects
	var space_state = get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = Vector3(grid_size * 0.9, 0.1, grid_size * 0.9)
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), world_pos + Vector3(0, 0.05, 0))
	query.collision_mask = 2  # Resources layer
	
	var results = space_state.intersect_shape(query)
	return results.is_empty()  # True if no objects at this position

func plant_seed_on_box():
	if not can_plant:
		return
		
	var world_pos = Vector3(
		selected_cell.x * grid_size,
		selected_cell.y * grid_size + 0.01, # Slightly above the box
		selected_cell.z * grid_size
	)
	
	# Create growing seed
	var growing_seed = Node3D.new()
	# Store the player info in the growing seed
	growing_seed.set_meta("player", current_player)
	growing_seed.set_meta("on_box", true)
	
	var timer = Timer.new()
	timer.wait_time = 15.0  # 15 seconds to grow
	timer.one_shot = true
	growing_seed.add_child(timer)
	growing_seed.position = world_pos
	
	# Add visual indicator for growing seed
	var grow_indicator = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.5, 0.5)  # Smaller than the full grid
	grow_indicator.mesh = quad_mesh
	grow_indicator.rotation_degrees = Vector3(90, 0, 0)  # Flat on box
	
	var mat = StandardMaterial3D.new()
	
	# Color the growing seed based on player
	if current_player == 1:
		mat.albedo_color = Color(0.8, 0.2, 0.2)  # Reddish for player 1
	else:
		mat.albedo_color = Color(0.2, 0.7, 0.2)  # Greenish for player 2
	
	grow_indicator.material_override = mat
	growing_seed.add_child(grow_indicator)
	
	# Connect timer to spawn actual dandelion
	timer.timeout.connect(_on_seed_grown.bind(growing_seed, world_pos))	
	# Add to scene tree BEFORE starting the timer
	add_child(growing_seed)
	
	# Now that it's in the tree, start the timer
	timer.start()
	
	# Reduce player's seed count if you want to track them
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("use_seed_for_planting"):
		player.use_seed_for_planting()

func plant_flower():
	if not can_plant:
		return
	
	var world_pos = Vector3(
		selected_cell.x * grid_size,
		0,
		selected_cell.z * grid_size
	)
	
	# Create growing flower
	var growing_flower = Node3D.new()
	# Store the player info in the growing flower
	growing_flower.set_meta("player", current_player)
	
	var timer = Timer.new()
	timer.wait_time = 15.0  # 15 seconds to grow
	timer.one_shot = true
	growing_flower.add_child(timer)
	growing_flower.position = world_pos
	
	# Add visual indicator for growing
	var grow_indicator = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	grow_indicator.mesh = sphere_mesh
	var mat = StandardMaterial3D.new()
	
	# Color the growing seed based on player
	if current_player == 1:
		mat.albedo_color = Color(0.8, 0.2, 0.2)  # Reddish for player 1
	else:
		mat.albedo_color = Color(0.8, 0.6, 0.2)  # Brown/yellow for player 2
	
	grow_indicator.material_override = mat
	growing_flower.add_child(grow_indicator)
	
	# Connect timer to spawn actual flower
	timer.timeout.connect(_on_flower_grown.bind(growing_flower, world_pos))
	
	# Add to scene tree BEFORE starting the timer
	add_child(growing_flower)
	
	# Now that it's in the tree, start the timer
	timer.start()
	
	# Reduce player's flower count for planting
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("use_flower_for_planting"):
		player.use_flower_for_planting()

func _on_seed_grown(growing_seed: Node3D, world_pos: Vector3):
	# Get which player planted this seed
	var player_number = growing_seed.get_meta("player", 1)
	
	# Remove growing indicator
	growing_seed.queue_free()
	
	var dandelion = null
	
	# Try to instantiate from the scene
	if dandelion_scene:
		# GDScript doesn't support try/except, so we'll check if it's valid first
		if dandelion_scene is PackedScene:
			dandelion = dandelion_scene.instantiate()
		else:
			print("Failed to instantiate dandelion from scene, creating one programmatically")
	
	# If scene instantiation failed, create one programmatically
	if not dandelion:
		print("Creating dandelion programmatically")
		dandelion = Node3D.new()
		dandelion.name = "CollectibleDandelion"
		
		# Try to load the dandelion mesh
		var dandelion_mesh = null
		var mesh_paths = [
			"res://assets/dandelions.obj",
			"res://scenes/scene2/assets/dandelions.obj"
		]
		
		for path in mesh_paths:
			if FileAccess.file_exists(path):
				dandelion_mesh = load(path)
				if dandelion_mesh != null:
					break
				
		# If we found the mesh, create a mesh instance
		if dandelion_mesh:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = dandelion_mesh
			dandelion.add_child(mesh_instance)
		else:
			# Create a simple placeholder mesh if we can't load the dandelion
			var mesh_instance = MeshInstance3D.new()
			var cube_mesh = BoxMesh.new()
			cube_mesh.size = Vector3(0.2, 0.2, 0.2)
			mesh_instance.mesh = cube_mesh
			dandelion.add_child(mesh_instance)
			
		# Add a script for collectible behavior
		dandelion.set_meta("points", 10)
		dandelion.set_meta("is_crystal", false)
				
		# Create an Area3D for collection
		var area = Area3D.new()
		var collision_shape = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.2, 0.2, 0.2)
		collision_shape.shape = shape
		
		area.add_child(collision_shape)
		area.collision_layer = 2  # Resources layer
		area.collision_mask = 1   # Players layer
		dandelion.add_child(area)
		
		# Connect signals
		area.body_entered.connect(func(body):
			if body.has_method("collect_resource"):
				body.collect_resource(dandelion.get_meta("points", 10), dandelion.get_meta("is_crystal", false))
				dandelion.queue_free())
	
	# Position the dandelion
	dandelion.position = world_pos
	
	# Set color based on player
	if player_number == 1:
		# Set the dandelion to be red for player 1
		set_flower_color(dandelion, Color(1, 0, 0))  # Red
	else:
		# Set the dandelion to be green for player 2
		set_flower_color(dandelion, Color(0, 1, 0))  # Green
	
	add_child(dandelion)
	print("Dandelion created at position: " + str(world_pos))

func _on_flower_grown(growing_flower: Node3D, world_pos: Vector3):
	# Get which player planted this flower
	var player_number = growing_flower.get_meta("player", 1)
	
	# Remove growing indicator
	growing_flower.queue_free()
	
	# Spawn actual collectible flower
	if flower_scene:
		var flower = flower_scene.instantiate()
		flower.position = world_pos
		
		# Set color based on player
		if player_number == 1:
			# Set the flower to be red for player 1
			set_flower_color(flower, Color(1, 0, 0))  # Red
		else:
			# Set the flower to be green for player 2
			set_flower_color(flower, Color(0, 1, 0))  # Green
		
		add_child(flower)

# Helper function to set flower color
func set_flower_color(flower: Node3D, color: Color):
	# Try to find the MeshInstance3D in the flower scene
	var mesh_instance = null
	
	if flower is MeshInstance3D:
		mesh_instance = flower
	else:
		# Try to find a MeshInstance3D child
		for child in flower.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	if mesh_instance:
		# Apply color to the mesh
		var material = mesh_instance.get_active_material(0)
		if material:
			# If it's using an existing material, clone it to avoid affecting other instances
			material = material.duplicate()
			material.albedo_color = color
			mesh_instance.set_surface_override_material(0, material)
		else:
			# Create new material if none exists
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = color
			mesh_instance.set_surface_override_material(0, new_material)
