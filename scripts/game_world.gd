extends Node3D

# Basic 3D game framework

func _ready():
	print("Game world initialized!")
	
	# Create a floor
	var floor = CSGBox3D.new()
	floor.name = "Floor"
	floor.size = Vector3(20, 1, 20)
	floor.position = Vector3(0, -0.5, 0)
	add_child(floor)
	
	# Create a simple player character
	var player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1, 0)
	add_child(player)
	
	# Add a collision shape to the player
	var collision = CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	player.add_child(collision)
	
	# Add a camera to the player
	var camera = Camera3D.new()
	camera.position = Vector3(0, 1.5, 0)
	player.add_child(camera)
	
	# Add a player controller script
	var script = load("res://scripts/player_controller.gd")
	if script:
		player.set_script(script)
	else:
		print("Player controller script not found!")

func _process(delta):
	# Game logic will go here
	pass
