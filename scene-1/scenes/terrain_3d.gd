extends Terrain3D

@export var max_height: float = 200.0 # Adjust as needed

func _ready():
	var heightmap_path: String = "res://heightmaps/fitz_roy_heightmap_16bit.png"
	var heightmap_texture: ImageTexture = load(heightmap_path)

	if heightmap_texture:
		self.heightmap = heightmap_texture # Use self to refer to the Terrain3D node's property
	else:
		printerr("Error: Could not load heightmap texture at:", heightmap_path)
		return

	# Set the terrain size
	self.size = Vector3(1400, max_height, 1400) # Use self

	# Adjust height range based on the 16-bit data (assuming full range is used)
	self.height_range_min = 0.0 # Use self
	self.height_range_max = max_height # Use self

	# Optional: If you want to use the heightmap as the base texture (not recommended for visual quality)
	# var base_texture: Texture2D = load(heightmap_path)
	# if base_texture:
	# 	var material = StandardMaterial3D.new()
	# 	material.albedo_texture = base_texture
	# 	material.texture_repeat = Vector3(1, 0, 1)
	# 	material.uv1_scale = Vector3(1, 0, 1)
	# 	material_override = material
	# else:
	# 	printerr("Error: Could not load base texture at:", heightmap_path)

	print("Terrain size set to:", self.size) # Use self
	print("Height range set to:", self.height_range_min, "to", self.height_range_max) # Use self
