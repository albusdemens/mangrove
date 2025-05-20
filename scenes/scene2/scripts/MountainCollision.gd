# Quick script to add to your mountain node
extends StaticBody3D

func _ready():
	# No debug visualization
	# get_viewport().set_debug_draw(3)  # Commented out to avoid warning
	
	add_to_group("mountain")
	# Ensure collision is sized appropriately
	for child in get_children():
		if child is CollisionShape3D:
			print("Found collision shape: ", child.name)
			return
	
	print("No collision shape found - creating one now")
	
	# Try multiple potential locations for the mesh
	var mesh_instance = null
	var locations = [
		"Mountain",       # Direct child - your actual mesh name
		"GodotMountain",  # Direct child
		"Mountain/GodotMountain",  # Child of Mountain
		"../GodotMountain",  # Sibling node
		"../Mountain/GodotMountain"  # Sibling's child
	]
	
	for location in locations:
		mesh_instance = get_node_or_null(location)
		if mesh_instance and mesh_instance is MeshInstance3D and mesh_instance.mesh:
			print("Found mesh at: ", location)
			break
		else:
			mesh_instance = null
	
	if mesh_instance:
		var shape = mesh_instance.mesh.create_trimesh_shape()
		var collision = CollisionShape3D.new()
		collision.shape = shape
		add_child(collision)
		print("Created convex collision shape from mesh")
		
		# Make sure collision layers are set properly
		collision_layer = 1
		collision_mask = 0  # Static bodies typically don't need to detect collisions
	else:
		print("ERROR: Couldn't find mesh to create collision from!")
		print("Available children of this node:")
		for child in get_children():
			print(" - ", child.name, " (", child.get_class(), ")")
		
		print("Available children of parent node:")
		if get_parent():
			for child in get_parent().get_children():
				print(" - ", child.name, " (", child.get_class(), ")")
		else:
			print("No parent node found")
			
		print("This node's path: ", get_path())
