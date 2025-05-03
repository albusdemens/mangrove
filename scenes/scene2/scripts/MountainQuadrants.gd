extends MeshInstance3D

@export var band1_normal: Vector3 = Vector3(1, 0, 0).normalized()
@export var band2_normal: Vector3 = Vector3(0, 0, 1).normalized()
@export var overlay_opacity: float = 0.3
@export var character_scale: float = 0.1
@export var motion_speed: float = 0.5
@export var motion_radius: float = 1.0  # Reduced radius to keep objects closer to center

# Define paths to 3D models for each character type
@export_dir var models_directory: String = "res://models/"
@export var cube_model_path: String = "res://models/cube.tscn"
@export var pyramid_model_path: String = "res://models/pyramid.tscn"
@export var sphere_model_path: String = "res://models/sphere.tscn"
@export var octahedron_model_path: String = "res://models/octahedron.tscn"

var highest_point: Vector3 = Vector3(0, 0, 0)
var characters = []

# Define quadrant colors - same as used in the shader
var quadrant_colors = {
	1: Color(1.0, 0.0, 0.0),  # Red - Q1
	2: Color(0.0, 1.0, 0.0),  # Green - Q2
	3: Color(0.0, 0.0, 1.0),  # Blue - Q3
	4: Color(1.0, 1.0, 0.0)   # Yellow - Q4
}

func _ready():
	# Find the highest point of the mesh
	find_highest_point()
	
	# Apply the quadrant overlay
	apply_quadrant_overlay()
	
	# Place characters at the highest point
	place_characters()

func find_highest_point():
	var mesh_data = get_mesh()
	if mesh_data:
		var highest_y = -INF
		var vertices: PackedVector3Array = PackedVector3Array()

		if mesh_data is ArrayMesh:
			var surface_count = mesh_data.get_surface_count()
			for i in range(surface_count):
				var arrays = mesh_data.surface_get_arrays(i)
				if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
					if vertices.is_empty():
						vertices = arrays[Mesh.ARRAY_VERTEX]
					else:
						vertices.append_array(arrays[Mesh.ARRAY_VERTEX])
		elif mesh_data is PrimitiveMesh:
			var arr_mesh = ArrayMesh.new()
			arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data.get_mesh_arrays())
			var arrays = arr_mesh.surface_get_arrays(0)
			if arrays.size() > 0:
				vertices = arrays[Mesh.ARRAY_VERTEX]

		if not vertices.is_empty():
			for vertex in vertices:
				var world_pos = global_transform * vertex
				if world_pos.y > highest_y:
					highest_y = world_pos.y
					highest_point = world_pos
			
			print("Highest point found at: ", highest_point)
		else:
			print("No vertices found in mesh")

func apply_quadrant_overlay():
	# Create a duplicate mesh for the overlay
	var overlay = MeshInstance3D.new()
	overlay.mesh = get_mesh().duplicate()
	overlay.name = "QuadrantOverlay"
	
	# Create transparent shader material
	var shader_mat = ShaderMaterial.new()
	var shader = Shader.new()
	
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform vec3 highest_point;
uniform vec3 band1_normal;
uniform vec3 band2_normal;
uniform float opacity;

void fragment() {
	// World position calculation
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Direction from highest point
	vec3 dir_to_highest = world_pos - highest_point;
	
	// Calculate quadrant
	float dist1 = dot(dir_to_highest, band1_normal);
	float dist2 = dot(dir_to_highest, band2_normal);
	
	// Set color based on quadrant
	vec4 color = vec4(0.5, 0.5, 0.5, 0.0);
	
	if (dist1 > 0.0 && dist2 > 0.0) {
		color = vec4(1.0, 0.0, 0.0, opacity); // Red - Q1
	} else if (dist1 < 0.0 && dist2 > 0.0) {
		color = vec4(0.0, 1.0, 0.0, opacity); // Green - Q2
	} else if (dist1 < 0.0 && dist2 < 0.0) {
		color = vec4(0.0, 0.0, 1.0, opacity); // Blue - Q3
	} else if (dist1 > 0.0 && dist2 < 0.0) {
		color = vec4(1.0, 1.0, 0.0, opacity); // Yellow - Q4
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
"""
	
	shader_mat.shader = shader
	shader_mat.set_shader_parameter("highest_point", highest_point)
	shader_mat.set_shader_parameter("band1_normal", band1_normal)
	shader_mat.set_shader_parameter("band2_normal", band2_normal)
	shader_mat.set_shader_parameter("opacity", overlay_opacity)
	
	# Apply material and offset slightly to prevent z-fighting
	overlay.material_override = shader_mat
	overlay.position += Vector3(0, 0.02, 0)
	
	# Add to scene
	add_child(overlay)
	print("Added quadrant overlay")

func place_characters():
	# Create a parent node to hold all characters
	var characters_container = Node3D.new()
	characters_container.name = "Characters"
	add_child(characters_container)
	
	# The shapes we'll create (4 types)
	var shape_types = ["Cube", "Pyramid", "Sphere", "Octahedron"]
	
	# Position offset around the highest point
	var base_height = highest_point.y + 2.0  # Position characters higher above the terrain for visibility
	
	# Place each shape type in each quadrant
	for quadrant in range(1, 5):
		var shape_type = shape_types[quadrant - 1]
		
		# Calculate 4 positions within this quadrant
		for i in range(4):
			# Calculate position - spread the objects out in their quadrant
			var angle = randf_range(0, PI/2) + (PI/2) * (quadrant - 1)
			var distance = randf_range(3.0, 5.0)
			var pos_x = highest_point.x + cos(angle) * distance
			var pos_z = highest_point.z + sin(angle) * distance
			
			# Create the character using the corresponding model or fallback
			var model_path = ""
			match shape_type:
				"Cube": model_path = cube_model_path
				"Pyramid": model_path = pyramid_model_path
				"Sphere": model_path = sphere_model_path
				"Octahedron": model_path = octahedron_model_path
			
			var character = load_character_model(shape_type, model_path, quadrant)
			
			if character:
				# Position the character
				character.position = Vector3(pos_x, base_height, pos_z)
				character.scale = Vector3(character_scale, character_scale, character_scale)
				
				# Store the original position for movement calculations
				character.set_meta("original_pos", Vector3(pos_x, base_height, pos_z))
				character.set_meta("movement_phase", randf() * 2.0 * PI)  # Random starting phase
				character.set_meta("quadrant", quadrant)  # Store the quadrant
				
				characters.append(character)
				characters_container.add_child(character)
				
				print("Placed ", shape_type, " at position ", character.position, " in quadrant ", quadrant)
			else:
				print("Failed to load model for ", shape_type)
			
	print("Placed characters at the highest point")

func load_character_model(shape_type: String, model_path: String, quadrant: int) -> Node3D:
	# Check if the model path exists
	if not FileAccess.file_exists(model_path):
		print("Model file not found: ", model_path)
		# Fall back to creating a primitive shape
		return create_fallback_shape(shape_type, quadrant)
	
	# Load the model
	var model_scene = load(model_path)
	if not model_scene:
		print("Failed to load model: ", model_path)
		return create_fallback_shape(shape_type, quadrant)
	
	# Instance the model scene
	var model_instance = model_scene.instantiate()
	if not model_instance:
		print("Failed to instantiate model: ", model_path)
		return create_fallback_shape(shape_type, quadrant)
	
	model_instance.name = shape_type
	
	# Set color based on quadrant
	var color = quadrant_colors[quadrant]
	
	# Try to find and update materials in the model
	apply_color_to_model(model_instance, color)
	
	return model_instance

func apply_color_to_model(node: Node, color: Color):
	# Recursively search for MeshInstance3D nodes and apply color
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		
		# Check for existing materials
		if mesh_instance.material_override:
			# Clone the material to avoid modifying the original
			var new_material = mesh_instance.material_override.duplicate()
			if new_material is BaseMaterial3D:
				new_material.albedo_color = color
				mesh_instance.material_override = new_material
		else:
			# Create a new material
			var new_material = StandardMaterial3D.new()
			new_material.albedo_color = color
			mesh_instance.material_override = new_material
	
	# Check child nodes
	for child in node.get_children():
		apply_color_to_model(child, color)

func create_fallback_shape(shape_type: String, quadrant: int) -> MeshInstance3D:
	print("Creating fallback shape for ", shape_type)
	var shape_instance = MeshInstance3D.new()
	shape_instance.name = shape_type
	
	# Create a different shape based on type
	match shape_type:
		"Cube":
			var box_mesh = BoxMesh.new()
			shape_instance.mesh = box_mesh
		"Pyramid":
			var prism_mesh = PrismMesh.new()
			prism_mesh.size = Vector3(1, 1, 1)
			shape_instance.mesh = prism_mesh
		"Sphere":
			var sphere_mesh = SphereMesh.new()
			shape_instance.mesh = sphere_mesh
		"Octahedron":
			# Better octahedron approximation
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radial_segments = 4
			sphere_mesh.rings = 2
			shape_instance.mesh = sphere_mesh
	
	# Set color based on quadrant
	var material = StandardMaterial3D.new()
	material.albedo_color = quadrant_colors[quadrant]
	
	shape_instance.material_override = material
	
	return shape_instance

func get_player_quadrant(player_position: Vector3) -> int:
	var local_player_pos = global_transform.inverse() * player_position
	var local_highest_point = global_transform.inverse() * highest_point
	var local_band1_normal = global_transform.basis.inverse() * band1_normal
	var local_band2_normal = global_transform.basis.inverse() * band2_normal

	var dist1 = local_player_pos.dot(local_band1_normal) - local_highest_point.dot(local_band1_normal)
	var dist2 = local_player_pos.dot(local_band2_normal) - local_highest_point.dot(local_band2_normal)

	if dist1 > 0.0 && dist2 > 0.0:
		return 1
	elif dist1 < 0.0 && dist2 > 0.0:
		return 2
	elif dist1 < 0.0 && dist2 < 0.0:
		return 3
	elif dist1 > 0.0 && dist2 < 0.0:
		return 4
	return 0

func _process(delta):
	# Update character movement
	update_character_movement(delta)
	
	# Check player quadrant
	var player = get_tree().get_first_node_in_group("players")
	if player:
		var _player_quadrant = get_player_quadrant(player.global_position)

func update_character_movement(delta):
	for character in characters:
		var original_pos = character.get_meta("original_pos")
		var phase = character.get_meta("movement_phase")
		var quadrant = character.get_meta("quadrant")
		
		# Update the phase
		phase += delta * motion_speed
		character.set_meta("movement_phase", phase)
		
		# Calculate new position with circular motion - adjust based on quadrant
		var angle_offset = (quadrant - 1) * PI/2  # 0, 90, 180, or 270 degrees
		var offset_x = cos(phase + angle_offset) * motion_radius
		var offset_z = sin(phase + angle_offset) * motion_radius
		
		# Add small up and down bobbing motion
		var offset_y = sin(phase * 2.0) * 0.3
		
		# Update position
		character.position = original_pos + Vector3(offset_x, offset_y, offset_z)
		
		# Also add a spinning effect
		character.rotation.y = phase
