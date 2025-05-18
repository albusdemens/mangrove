extends StaticBody3D

func _ready():
	# Wait one frame to ensure mesh is loaded
	await get_tree().process_frame
	
	# Find the mesh instance
	var mesh_instance = $Mountain  # Change to match your node name!
	
	if mesh_instance and mesh_instance is MeshInstance3D and mesh_instance.mesh:
		print("Found mesh, creating collision...")
		create_collision_from_mesh(mesh_instance)
	else:
		print("Mesh not found or invalid")

func create_collision_from_mesh(mesh_instance):
	var mesh = mesh_instance.mesh
	
	# Create collision from triangles
	if mesh.get_surface_count() > 0:
		# Option A: Create proper concave shape
		var shape = ConcavePolygonShape3D.new()
		var arrays = mesh.surface_get_arrays(0)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		var indices
		
		# Check if we have indices
		if arrays[Mesh.ARRAY_INDEX].size() > 0:
			indices = arrays[Mesh.ARRAY_INDEX]
			print("Using indexed geometry with ", indices.size(), " indices")
		else:
			# No indices, assume vertices are already organized as triangles
			print("Using non-indexed geometry with ", vertices.size(), " vertices")
			
		# Build the face array properly
		var faces = PackedVector3Array()
		
		if indices:
			# For indexed geometry
			for i in range(0, indices.size(), 3):
				if i + 2 < indices.size():
					faces.append(vertices[indices[i]])
					faces.append(vertices[indices[i+1]])
					faces.append(vertices[indices[i+2]])
		else:
			# For non-indexed geometry
			for i in range(0, vertices.size(), 3):
				if i + 2 < vertices.size():
					faces.append(vertices[i])
					faces.append(vertices[i+1])
					faces.append(vertices[i+2])
		
		print("Created faces array with ", faces.size(), " vertices")
		
		# Only proceed if we have valid triangles
		if faces.size() > 0 and faces.size() % 3 == 0:
			shape.set_faces(faces)
			
			var collision = CollisionShape3D.new()
			collision.shape = shape
			add_child(collision)
			print("Created concave collision shape with ", faces.size() / 3.0, " triangles")
		else:
			print("Failed to create valid faces array")
			# Fall back to simple box collision
			create_simple_box_collision(mesh_instance)
	else:
		print("Mesh has no surfaces")
		create_simple_box_collision(mesh_instance)

func create_simple_box_collision(mesh_instance):
	print("Creating simple box collision instead")
	var aabb = mesh_instance.get_aabb()
	
	var shape = BoxShape3D.new()
	shape.size = aabb.size
	
	var collision = CollisionShape3D.new()
	collision.shape = shape
	collision.position = aabb.position + aabb.size/2
	add_child(collision)
	print("Created box collision with size: ", aabb.size)
