@tool
extends Node3D

# Configurable stripe properties
@export var stripe_color: Color = Color(1.0, 1.0, 1.0, 0.8)  # White with transparency
@export var stripe_width: float = 0.2  # Width of the stripe lines
@export var quadrant_colors: Dictionary = {
	"northwest": Color(1.0, 0.0, 0.0, 0.3),   # Red
	"northeast": Color(0.0, 1.0, 0.0, 0.3),   # Green
	"southwest": Color(0.0, 0.0, 1.0, 0.3),   # Blue
	"southeast": Color(1.0, 1.0, 0.0, 0.3)    # Yellow
}
@export var show_quadrant_overlays: bool = true
@export var show_labels: bool = true

# Store quadrant information
var quadrants = {}
var mountain_top_y = 0.0
var center_x = 0.0
var center_z = 0.0

# Visual elements for quadrants
var quadrant_visuals = {}

func _ready():
	setup_quadrants()
	create_visual_separators()

func setup_quadrants():
	# Get the mountain's bounding box
	var mountain = $Mountain
	if not mountain or not mountain.mesh:
		return  # Safety check for editor
		
	var aabb = mountain.mesh.get_aabb()
	mountain_top_y = aabb.end.y
	center_x = aabb.get_center().x
	center_z = aabb.get_center().z
	
	# Define quadrant boundaries
	quadrants["northwest"] = {
		"min_x": aabb.position.x,
		"max_x": center_x,
		"min_z": aabb.position.z,
		"max_z": center_z
	}
	
	quadrants["northeast"] = {
		"min_x": center_x,
		"max_x": aabb.end.x,
		"min_z": aabb.position.z,
		"max_z": center_z
	}
	
	quadrants["southwest"] = {
		"min_x": aabb.position.x,
		"max_x": center_x,
		"min_z": center_z,
		"max_z": aabb.end.z
	}
	
	quadrants["southeast"] = {
		"min_x": center_x,
		"max_x": aabb.end.x,
		"min_z": center_z,
		"max_z": aabb.end.z
	}

func create_visual_separators():
	# Create a material for the divider lines
	var line_material = StandardMaterial3D.new()
	line_material.albedo_color = stripe_color
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Get mountain bounds for line sizing
	var mountain = $Mountain
	if not mountain or not mountain.mesh:
		return
		
	var aabb = mountain.mesh.get_aabb()
	var size_x = aabb.size.x * 1.2  # Make lines 20% longer than mountain
	var size_z = aabb.size.z * 1.2
	
	# Create vertical line (North-South)
	var vertical_line = MeshInstance3D.new()
	var vertical_mesh = BoxMesh.new()
	vertical_mesh.size = Vector3(stripe_width, 0.1, size_z)
	vertical_line.mesh = vertical_mesh
	vertical_line.material_override = line_material
	vertical_line.position = Vector3(center_x, mountain_top_y + 0.05, center_z)
	add_child(vertical_line)
	
	# Make it visible in editor
	if Engine.is_editor_hint():
		vertical_line.owner = get_tree().edited_scene_root
	
	# Create horizontal line (East-West)
	var horizontal_line = MeshInstance3D.new()
	var horizontal_mesh = BoxMesh.new()
	horizontal_mesh.size = Vector3(size_x, 0.1, stripe_width)
	horizontal_line.mesh = horizontal_mesh
	horizontal_line.material_override = line_material
	horizontal_line.position = Vector3(center_x, mountain_top_y + 0.05, center_z)
	add_child(horizontal_line)
	
	# Make it visible in editor
	if Engine.is_editor_hint():
		horizontal_line.owner = get_tree().edited_scene_root
	
	# Create quadrant overlays if enabled
	if show_quadrant_overlays:
		create_quadrant_overlays()

func create_quadrant_overlays():
	# Clear existing overlays
	for quad_name in quadrant_visuals:  # Changed from "name" to "quad_name"
		if quadrant_visuals[quad_name]:
			quadrant_visuals[quad_name].queue_free()
	quadrant_visuals.clear()
	
	for quadrant_name in quadrants:
		var q = quadrants[quadrant_name]
		
		# Create a quad mesh for the quadrant overlay
		var overlay = MeshInstance3D.new()
		var mesh = PlaneMesh.new()
		
		# Calculate size
		var width = abs(q.max_x - q.min_x)
		var depth = abs(q.max_z - q.min_z)
		mesh.size = Vector2(width, depth)
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = quadrant_colors.get(quadrant_name, Color.GRAY)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		overlay.mesh = mesh
		overlay.material_override = material
		
		# Position at center of quadrant
		var center_pos = Vector3(
			(q.min_x + q.max_x) / 2,
			mountain_top_y + 0.02,
			(q.min_z + q.max_z) / 2
		)
		overlay.position = center_pos
		overlay.rotate_x(deg_to_rad(-90))
		
		add_child(overlay)
		
		# Make visible in editor
		if Engine.is_editor_hint():
			overlay.owner = get_tree().edited_scene_root
		
		quadrant_visuals[quadrant_name] = overlay
		
		# Add labels if enabled
		if show_labels:
			var label = Label3D.new()
			label.text = quadrant_name
			label.position = center_pos + Vector3(0, 5, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.outline_size = 10
			label.outline_modulate = Color.BLACK
			label.font_size = 20
			add_child(label)
			
			# Make visible in editor
			if Engine.is_editor_hint():
				label.owner = get_tree().edited_scene_root

# Function to update visuals when editor properties change
func _validate_property(property):
	if property.name in ["stripe_color", "stripe_width", "quadrant_colors", "show_quadrant_overlays", "show_labels"]:
		if Engine.is_editor_hint():
			# Rebuild visuals when properties change
			call_deferred("rebuild_visuals")

func rebuild_visuals():
	# Clear existing visuals
	for child in get_children():
		if child is MeshInstance3D or child is Label3D:
			child.queue_free()
	
	create_visual_separators()

# Function to get quadrant at position (for gameplay use)
func get_quadrant_at_position(pos: Vector3) -> String:
	for quadrant_name in quadrants:
		var q = quadrants[quadrant_name]
		if pos.x >= q.min_x and pos.x <= q.max_x and pos.z >= q.min_z and pos.z <= q.max_z:
			return quadrant_name
	return ""  # Not in any quadrant

# Function to move character to their quadrant
func move_character_to_quadrant(character, character_type):
	var target_quadrant
	match character_type:
		"type1": target_quadrant = "northwest"
		"type2": target_quadrant = "northeast"
		"type3": target_quadrant = "southwest"
		"type4": target_quadrant = "southeast"
	
	# Get center of target quadrant
	var q = quadrants[target_quadrant]
	var target_position = Vector3(
		(q.min_x + q.max_x) / 2,
		mountain_top_y,
		(q.min_z + q.max_z) / 2
	)
	
	character.move_to(target_position)
