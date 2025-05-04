extends Node3D  # For Godot 4

@export_range(0.01, 0.5) var band_width: float = 0.05
@export var band_color: Color = Color(1.0, 0.0, 0.0)
@export var q1_color: Color = Color(0.8, 0.2, 0.2)  # Bottom-left
@export var q2_color: Color = Color(0.2, 0.8, 0.2)  # Bottom-right
@export var q3_color: Color = Color(0.2, 0.2, 0.8)  # Top-left
@export var q4_color: Color = Color(0.8, 0.8, 0.2)  # Top-right

func _ready():
	var mountain = $Mountain  # Adjust to match your node path
	apply_quadrant_material(mountain)

func apply_quadrant_material(mesh_instance):
	# Create a new shader material
	var material = ShaderMaterial.new()
	var shader = Shader.new()
	
	# Define the shader code
	shader.code = """
	shader_type spatial;
	
	uniform float band_width : hint_range(0.01, 0.5);
	uniform vec4 band_color : hint_color;
	uniform vec4 q1_color : hint_color;
	uniform vec4 q2_color : hint_color;
	uniform vec4 q3_color : hint_color;
	uniform vec4 q4_color : hint_color;
	
	void fragment() {
		// Use UV coordinates if available
		vec2 uv = UV;
		
		// Calculate distance from the center bands (horizontal and vertical)
		float dist_x = abs(uv.x - 0.5);
		float dist_y = abs(uv.y - 0.5);
		
		// If within band width, use band color
		if (dist_x < band_width || dist_y < band_width) {
			ALBEDO = band_color.rgb;
		} else {
			// Otherwise use quadrant colors
			if (uv.x < 0.5 && uv.y < 0.5) {
				ALBEDO = q1_color.rgb; // Bottom-left
			} else if (uv.x >= 0.5 && uv.y < 0.5) {
				ALBEDO = q2_color.rgb; // Bottom-right
			} else if (uv.x < 0.5 && uv.y >= 0.5) {
				ALBEDO = q3_color.rgb; // Top-left
			} else {
				ALBEDO = q4_color.rgb; // Top-right
			}
		}
	}
	"""
	
	# Assign shader to material
	material.shader = shader
	
	# Set the material parameters
	material.set_shader_param("band_width", band_width)
	material.set_shader_param("band_color", band_color)
	material.set_shader_param("q1_color", q1_color)
	material.set_shader_param("q2_color", q2_color)
	material.set_shader_param("q3_color", q3_color)
	material.set_shader_param("q4_color", q4_color)
	
	# Apply material to mesh
	mesh_instance.material_override = material
