extends Node

func _ready():
	# Get the WorldEnvironment node
	var world_env = get_node("/root/WorldEnvironment")
	
	# Get the current environment resource
	var environment = world_env.environment
	
	# Set up some improved environment settings
	
	# Ambient light (for better shadows)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.5
	
	# Sky settings
	if environment.sky == null:
		environment.sky = Sky.new()
		var sky_material = ProceduralSkyMaterial.new()
		environment.sky.sky_material = sky_material
	
	# Add some fog for depth
	environment.fog_enabled = true
	environment.fog_density = 0.005
	environment.fog_sky_affect = 0.2
	
	# Add SSAO for better depth perception
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 3.0
	
	# Add some subtle glow
	environment.glow_enabled = true
	environment.glow_intensity = 0.3
	environment.glow_bloom = 0.1
	
	# Apply antialiasing
	get_viewport().msaa_3d = Viewport.MSAA_4X
	
	print("Environment settings applied!")
