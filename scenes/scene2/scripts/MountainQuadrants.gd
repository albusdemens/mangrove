extends MeshInstance3D

@export var band1_normal: Vector3 = Vector3(1, 0, 0).normalized()
@export var band2_normal: Vector3 = Vector3(0, 0, 1).normalized()
@export var overlay_opacity: float = 0.3

var highest_point: Vector3 = Vector3(0, 0, 0)

# Define quadrant colors
var quadrant_colors = {
	1: Color(1.0, 0.0, 0.0),  # Red - Q1
	2: Color(0.0, 1.0, 0.0),  # Green - Q2
	3: Color(0.0, 0.0, 1.0),  # Blue - Q3
	4: Color(1.0, 1.0, 0.0)   # Yellow - Q4
}

func _ready():
	find_highest_point()
	apply_quadrant_overlay()

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
	var overlay = MeshInstance3D.new()
	overlay.mesh = get_mesh().duplicate()
	overlay.name = "QuadrantOverlay"
	
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
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 dir_to_highest = world_pos - highest_point;
	
	float dist1 = dot(dir_to_highest, band1_normal);
	float dist2 = dot(dir_to_highest, band2_normal);
	
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
	
	overlay.material_override = shader_mat
	overlay.position += Vector3(0, 0.02, 0)
	
	add_child(overlay)
	print("Added quadrant overlay")

func get_quadrant(world_position: Vector3) -> int:
	var local_pos = global_transform.inverse() * world_position
	var local_highest_point = global_transform.inverse() * highest_point
	var local_band1_normal = global_transform.basis.inverse() * band1_normal
	var local_band2_normal = global_transform.basis.inverse() * band2_normal

	var dist1 = local_pos.dot(local_band1_normal) - local_highest_point.dot(local_band1_normal)
	var dist2 = local_pos.dot(local_band2_normal) - local_highest_point.dot(local_band2_normal)

	if dist1 > 0.0 && dist2 > 0.0:
		return 1
	elif dist1 < 0.0 && dist2 > 0.0:
		return 2
	elif dist1 < 0.0 && dist2 < 0.0:
		return 3
	elif dist1 > 0.0 && dist2 < 0.0:
		return 4
	return 0

# Methods to expose for other scripts
func get_highest_point() -> Vector3:
	return highest_point

func get_quadrant_color(quadrant: int) -> Color:
	return quadrant_colors[quadrant]
