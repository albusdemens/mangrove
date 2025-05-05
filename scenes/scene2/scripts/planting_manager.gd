# PlantingManager.gd
extends Node3D

@export var grid_size: float = 1.0  # Size of each grid cell
@export var planting_height: float = 0.5  # Height for planting indicator
@export var flower_scene: PackedScene  # Reference to your flower scene

var camera: Camera3D
var selected_cell: Vector3i = Vector3i(-999, -999, -999)  # Invalid position
var can_plant: bool = false
var plant_indicator: MeshInstance3D

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

func _process(_delta):
	if camera:
		update_planting_position()
		
		# Plant when clicking
		if Input.is_action_just_pressed("plant") and can_plant:
			plant_flower()

func update_planting_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000
	
	# Raycast to find ground
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Environment layer
	var result = space_state.intersect_ray(query)
	
	if result:
		# Snap to grid
		var world_pos = result.position
		var grid_pos = Vector3i(
			round(world_pos.x / grid_size),
			0,  # Keep it on ground level
			round(world_pos.z / grid_size)
		)
		
		selected_cell = grid_pos
		
		# Check if position is valid
		can_plant = is_valid_planting_spot(grid_pos)
		
		# Update indicator
		plant_indicator.position = Vector3(
			grid_pos.x * grid_size,
			planting_height,
			grid_pos.z * grid_size
		)
		plant_indicator.visible = true
		
		# Change color based on validity
		var mat = plant_indicator.material_override as StandardMaterial3D
		if can_plant:
			mat.albedo_color = Color(0, 1, 0, 0.5)  # Green if valid
		else:
			mat.albedo_color = Color(1, 0, 0, 0.5)  # Red if invalid
	else:
		plant_indicator.visible = false

func is_valid_planting_spot(grid_pos: Vector3i) -> bool:
	# Check if there's already something at this position
	var world_pos = Vector3(grid_pos.x * grid_size, 0, grid_pos.z * grid_size)
	
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
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	growing_flower.add_child(timer)
	growing_flower.position = world_pos
	
	# Add visual indicator for growing
	var grow_indicator = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	grow_indicator.mesh = sphere_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.6, 0.2)  # Brown for sprouting
	grow_indicator.material_override = mat
	growing_flower.add_child(grow_indicator)
	
	# Connect timer to spawn actual flower
	timer.timeout.connect(_on_flower_grown.bind(growing_flower, world_pos))
	timer.start()
	
	add_child(growing_flower)
	
	# Reduce player's flower count for planting
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("use_flower_for_planting"):
		player.use_flower_for_planting()

func _on_flower_grown(growing_flower: Node3D, world_pos: Vector3):
	# Remove growing indicator
	growing_flower.queue_free()
	
	# Spawn actual collectible flower
	if flower_scene:
		var flower = flower_scene.instantiate()
		flower.position = world_pos
		add_child(flower)
