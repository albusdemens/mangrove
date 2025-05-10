extends Node3D

@export var fishing_duration: float = 5.0  # Time it takes to catch something
@export var catch_probability: float = 0.7  # Probability of catching something

# Called when a player reaches this fishing spot
func start_fishing(player):
	# Visual feedback that fishing has started
	$MeshInstance3D.material_override.albedo_color = Color(0.0, 0.7, 1.0)
	
	# Wait for fishing duration
	await get_tree().create_timer(fishing_duration).timeout
	
	# Determine if catch was successful based on probability
	var success = randf() < catch_probability
	if success:
		# Create a gem at this position
		var gem = create_gem()
		get_parent().add_child(gem)
		gem.global_position = global_position + Vector3(0, 0.5, 0)
		
		# Visual feedback for successful catch
		$MeshInstance3D.material_override.albedo_color = Color(0.0, 1.0, 0.0)
	else:
		# Visual feedback for failed catch
		$MeshInstance3D.material_override.albedo_color = Color(1.0, 0.0, 0.0)
	
	# Reset color after a delay
	await get_tree().create_timer(1.0).timeout
	$MeshInstance3D.material_override.albedo_color = Color(0.2, 0.6, 0.8)
	
	return success

# Creates a collectible gem
func create_gem():
	# Create a new gem
	var gem_node = MeshInstance3D.new()
	gem_node.name = "FishedGem"
	
	# Add to blue_gems group for the NPC to target
	gem_node.add_to_group("blue_gems")
	
	# Create a simple mesh for the gem
	var gem_mesh = PrismMesh.new()
	gem_mesh.size = Vector3(0.3, 0.3, 0.3)
	gem_node.mesh = gem_mesh
	
	# Create a material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 1.0)  # Blue color
	material.metallic = 0.8
	material.roughness = 0.2
	gem_node.material_override = material
	
	# Add the CollectibleResource script for collection
	if ResourceLoader.exists("res://scripts/CollectibleResource.gd"):
		var script = load("res://scripts/CollectibleResource.gd")
		gem_node.set_script(script)
		gem_node.points = 100  # Higher value for fished gems
		gem_node.is_crystal = true
	
	# Add collision shape
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.3, 0.3, 0.3)
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
	gem_node.add_child(static_body)
	
	return gem_node
