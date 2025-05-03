@tool # Add this to make the script run in editor
extends MeshInstance3D

@export var band1_normal: Vector3 = Vector3(1, 0, 0).normalized()
@export var band2_normal: Vector3 = Vector3(0, 0, 1).normalized()
@export var overlay_opacity: float = 0.15 # Adjust transparency level
@export var update_overlay: bool = false: set = _update_overlay # Button to update in editor

var highest_point: Vector3 = Vector3(0, 0, 0)
var original_material = null
var overlay: MeshInstance3D = null

func _update_overlay(_value):
	update_overlay = false # Reset the button
	if Engine.is_editor_hint():
		# Remove existing overlay if any
		if overlay and overlay.is_inside_tree():
			overlay.queue_free()
			await get_tree().process_frame
		# Create new overlay
		calculate_highest_point()
		create_quadrant_overlay()

func _ready():
	if not Engine.is_editor_hint():
		# Only do this at runtime, not in editor
		calculate_highest_point()
		create_quadrant_overlay()

func calculate_highest_point():
	# Store the original material
	if material_override:
		original_material = material_override
	
	# Find the highest point of the mesh in world space
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
		else:
			printerr("Error: Unsupported mesh type.")
			return

		if not vertices.is_empty():
			for vertex in vertices:
				var world_pos = global_transform * vertex
				if world_pos.y > highest_y:
					highest_y = world_pos.y
					highest_point = world_pos
			
			print("Highest point found at: ", highest_point)
		else:
			print("No vertices found in mesh")

func create_quadrant_overlay():
	# Create a duplicate of the mesh to use as an overlay
	overlay = MeshInstance3D.new()
	overlay.mesh = mesh.duplicate()
	overlay.name = "QuadrantOverlay"
	
	# Create the overlay shader material
	var shader_mat = ShaderMaterial.new()
	var shader = Shader.new()
	
	# Shader for transparent quadrant colors
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_test_disabled, unshaded;

uniform vec3 highest_point = vec3(0.0, 0.0, 0.0);
uniform vec3 band1_normal = vec3(1.0, 0.0, 0.0);
uniform vec3 band2_normal = vec3(0.0, 0.0, 1.0);
uniform float opacity = 0.3;

void fragment() {
	// Get world position
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calculate direction vectors
	vec3 dir_to_highest = world_pos - highest_point;
	
	// Calculate distance from planes
	float dist1 = dot(dir_to_highest, band1_normal);
	float dist2 = dot(dir_to_highest, band2_normal);
	
	// Assign colors based on quadrant with transparency
	vec4 color = vec4(0.5, 0.5, 0.5, 0.0); // Default transparent
	
	if (dist1 > 0.0 && dist2 > 0.0) {
		color = vec4(1.0, 0.0, 0.0, opacity); // Quadrant 1: Red
	} else if (dist1 < 0.0 && dist2 > 0.0) {
		color = vec4(0.0, 1.0, 0.0, opacity); // Quadrant 2: Green
	} else if (dist1 < 0.0 && dist2 < 0.0) {
		color = vec4(0.0, 0.0, 1.0, opacity); // Quadrant 3: Blue
	} else if (dist1 > 0.0 && dist2 < 0.0) {
		color = vec4(1.0, 1.0, 0.0, opacity); // Quadrant 4: Yellow
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
	
	# Apply the material to the overlay
	overlay.material_override = shader_mat
	
	# Position the overlay slightly above the mountain to prevent z-fighting
	overlay.position = Vector3(0, 0.01, 0) # Small offset to prevent z-fighting
	
	# Add the overlay as a child
	add_child(overlay)
	
	# Make sure the overlay is properly set up in the scene tree
	overlay.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else owner
	
	print("Added quadrant overlay with transparency")

func get_player_quadrant(player_position: Vector3) -> int:
	# Transform player position to the mountain's local space
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
	return 0 # Or some default value if needed

func _process(_delta):
	if not Engine.is_editor_hint(): # Only run this at runtime
		var player = get_tree().get_first_node_in_group("players")
		if player:
			var _player_quadrant = get_player_quadrant(player.global_position)
			# Uncomment to debug:
			# print("Player is in quadrant:", _player_quadrant)
