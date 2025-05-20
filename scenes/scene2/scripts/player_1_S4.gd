extends RigidBody3D

# Movement and placement settings
var move_distance := 0.1
var boxes_placed := 0
var box_size := 1.0

# Scenes to instance
var box_scene: PackedScene

# Reference to mountain
var mountain_mesh

# Ready flag
var is_ready := false

# Array of reddish colors for the boxes
var red_colors := [
	Color(1.0, 0.0, 0.0),
	Color(0.8, 0.2, 0.2),
	Color(0.6, 0.0, 0.0),
	Color(0.9, 0.3, 0.3),
	Color(0.7, 0.1, 0.2),
	Color(0.5, 0.0, 0.1)
]

func _ready():
	freeze = true
	box_scene = preload("res://box.tscn")

	var mountains = get_tree().get_nodes_in_group("mountain")
	if mountains.size() > 0:
		mountain_mesh = mountains[0]

	is_ready = true

func _physics_process(_delta):
	if not is_ready:
		return

	var move_direction := Vector3.ZERO

	if Input.is_action_just_pressed("move_right"):
		move_direction = Vector3(move_distance, 0, 0)
	elif Input.is_action_just_pressed("move_left"):
		move_direction = Vector3(-move_distance, 0, 0)
	elif Input.is_action_just_pressed("move_forward"):
		move_direction = Vector3(0, 0, -move_distance)
	elif Input.is_action_just_pressed("move_backward"):
		move_direction = Vector3(0, 0, move_distance)
	elif Input.is_action_just_pressed("move_up"):
		move_direction = Vector3(0, move_distance, 0)
	elif Input.is_action_just_pressed("move_down"):
		move_direction = Vector3(0, -move_distance, 0)

	if move_direction != Vector3.ZERO:
		handle_movement(move_direction)

func handle_movement(direction: Vector3):
	if not is_inside_tree() or not is_ready:
		return

	if is_on_plane():
		global_position += direction
	else:
		call_deferred("place_box", direction)
		global_position += direction  # Move the player after requesting box placement

func is_on_plane() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + Vector3(0, -1.0, 0)
	)
	var result = space_state.intersect_ray(query)
	return result and result.position.distance_to(global_position) < 1.1

func place_box(_direction: Vector3):
	if not is_inside_tree() or not is_ready:
		print("place_box called too early. Skipping.")
		return

	var box = box_scene.instantiate()
	get_parent().add_child(box)  # Must be added before setting transform
	box.global_position = global_position

	# Apply random reddish color
	var mesh_instance = box.get_node("MeshInstance3D")
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = red_colors[randi() % red_colors.size()]
		mesh_instance.material_override = material

	boxes_placed += 1

	if boxes_placed % 10 == 0:
		call_deferred("create_pillar")

func create_pillar():
	var base_point = find_closest_point_on_mountain()
	var height = global_position.y - base_point.y
	var steps = int(height / box_size)

	for i in range(steps):
		var box = box_scene.instantiate()
		get_parent().add_child(box)
		box.global_position = base_point + Vector3(0, i * box_size, 0)

		var mesh_instance = box.get_node("MeshInstance3D")
		if mesh_instance:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = red_colors[i % red_colors.size()]
			mesh_instance.material_override = mat

func find_closest_point_on_mountain() -> Vector3:
	if mountain_mesh:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			global_position,
			global_position + Vector3(0, -100.0, 0)
		)
		var result = space_state.intersect_ray(query)
		if result:
			return result.position

	# Fallback if raycast fails
	return Vector3(global_position.x, 0, global_position.z)
