extends Node3D

func _ready():
	# Create the environment
	create_environment()
	
	# Create the floor
	create_floor()
	
	# Add a light
	add_light()
	
	# Create player
	create_player()
	
	print("Main game scene initialized!")

func create_environment():
	# Create a WorldEnvironment node
	var env = WorldEnvironment.new()
	env.name = "WorldEnvironment"
	
	# Create an Environment resource
	var environment = Environment.new()
	
	# Set up basic environment properties
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.4, 0.6, 0.8)
	environment.ambient_light_color = Color(0.3, 0.3, 0.3)
	environment.fog_enabled = true
	environment.fog_density = 0.01
	
	# Assign the environment resource
	env.environment = environment
	
	# Add to scene
	add_child(env)

func create_floor():
	# Create a floor mesh
	var floor_mesh = CSGBox3D.new()
	floor_mesh.name = "Floor"
	floor_mesh.size = Vector3(50, 1, 50)
	floor_mesh.position = Vector3(0, -0.5, 0)
	
	# Add to scene
	add_child(floor_mesh)

func add_light():
	# Create a directional light
	var light = DirectionalLight3D.new()
	light.name = "Sun"
	light.rotation = Vector3(-0.8, 0.5, 0)
	light.light_energy = 1.5
	
	# Add to scene
	add_child(light)

func create_player():
	# Create a character body for the player
	var player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1, 0)
	
	# Add a collision shape
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape"
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	
	# Add a camera
	var camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, 0.8, 0)
	player.add_child(camera)
	
	# Add a temporary visual representation (will be replaced with a proper model later)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TempVisual"
	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = 0.5
	capsule_mesh.height = 1.8
	mesh_instance.mesh = capsule_mesh
	player.add_child(mesh_instance)
	
	# Attach the player controller script
	var script = load("res://scripts/player_controller.gd")
	player.set_script(script)
	
	# Add to scene
	add_child(player)

func _process(delta):
	# Main game loop will go here
	pass
