extends Node3D

# Preload scenes
var seed_scene = preload("res://soil_tile.tscn")
var flower_scene = preload("res://grown_flower_tile.tscn")

# References
@onready var grid_map = $GridMap
@onready var camera = $Camera3D
@onready var ui_node = $UI  # Reference to the UI node
@onready var resource_counter = $UI/ResourceCounter

# Game state
var current_mode = "PLACE_SOIL"  # Modes: PLACE_SOIL, PLANT_SEED, COLLECT
var planted_items = {}  # Dictionary to track planted items by position

func _ready():
	ui_node = get_node_or_null("UI")
	if not ui_node:
		print("Error: UI node not found in the scene tree.")
		return

	# Ensure the ResourceCounter node is valid
	if not resource_counter:
		print("Error: ResourceCounter node not found.")
		return

	# Example: Initialize the coin count to 0
	resource_counter.update_coin_count(0)

	pass

func _process(_delta):
	# Check if the current camera is the third-person camera
	if camera.current:
		ui_node.visible = true  # Show the UI when in third-person view
	else:
		ui_node.visible = false  # Hide the UI otherwise

	if Input.is_action_just_pressed("plant"):
		handle_click()

func handle_click():
	# Get 3D position from mouse click
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		match current_mode:
			"PLACE_SOIL":
				place_soil_at(result.position)
			"PLANT_SEED":
				plant_seed_at(result.position)
			"COLLECT":
				try_collect_at(result.position)

func place_soil_at(world_position):
	# Convert world position to GridMap cell position
	var cell_pos = grid_map.local_to_map(world_position)
	
	# Check if cell is already occupied
	if grid_map.get_cell_item(cell_pos) != -1:
		return
	
	# Place soil tile at cell position
	grid_map.set_cell_item(cell_pos, 0)  # 0 is the item index in your MeshLibrary
	
	# Switch to seed planting mode
	current_mode = "PLANT_SEED"
	print("Soil placed. Now in seed planting mode.")

func plant_seed_at(world_position):
	# Convert world position to GridMap cell position
	var cell_pos = grid_map.local_to_map(world_position)
	
	# Check if there's soil at this position
	if grid_map.get_cell_item(cell_pos) == -1:
		return
	
	# Check if a seed is already planted here
	var cell_key = str(cell_pos)
	if cell_key in planted_items:
		return
	
	# Get world position of the cell center
	var world_pos = grid_map.map_to_local(cell_pos)
	world_pos.y += 0.5  # Offset to place on top of soil
	
	# Instantiate seed
	var seed_instance = seed_scene.instantiate()
	seed_instance.position = world_pos
	add_child(seed_instance)
	
	# Store reference
	planted_items[cell_key] = {
		"object": seed_instance,
		"type": "seed"
	}
	
	# Start growth timer
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 15.0
	add_child(timer)
	timer.timeout.connect(func(): grow_flower(cell_key))
	timer.start()
	
	# Switch back to soil placement mode
	current_mode = "PLACE_SOIL"
	print("Seed planted. Back to soil placement mode.")

func grow_flower(cell_key):
	# Make sure the seed still exists
	if cell_key in planted_items and planted_items[cell_key]["type"] == "seed":
		# Get the seed position
		var seed_instance = planted_items[cell_key]["object"]
		var pos = seed_instance.position
		
		# Remove the seed
		seed_instance.queue_free()
		
		# Instantiate flower
		var flower_instance = flower_scene.instantiate()
		flower_instance.position = pos
		add_child(flower_instance)
		
		# Connect flower's collected signal
		flower_instance.connect("collected", func(): on_flower_collected(cell_key))
		
		# Update reference
		planted_items[cell_key] = {
			"object": flower_instance,
			"type": "flower"
		}
		
		# Switch to collect mode
		current_mode = "COLLECT"
		print("A flower has grown! Click to collect.")

func try_collect_at(world_position):
	# Convert world position to GridMap cell position
	var cell_pos = grid_map.local_to_map(world_position)
	var cell_key = str(cell_pos)
	
	# Check if there's a flower at this position
	if cell_key in planted_items and planted_items[cell_key]["type"] == "flower":
		# The flower's input_event will handle collection
		pass

func on_flower_collected(cell_key):
	# Remove reference
	planted_items.erase(cell_key)
	
	# Switch back to soil placement mode
	current_mode = "PLACE_SOIL"
	print("Flower collected! Back to soil placement mode.")

func update_coins(new_count: int):
	# Update the coin count dynamically
	if resource_counter:
		resource_counter.update_coin_count(new_count)
