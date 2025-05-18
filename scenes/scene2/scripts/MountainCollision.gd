extends StaticBody3D

func _ready():
	# Get the mesh instance that's a child of this node
	var mesh_instance = $GodotMountain
	
	if mesh_instance and mesh_instance.mesh:
		var shape = mesh_instance.mesh.create_trimesh_shape()
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = shape
		add_child(collision_shape)
		print("Added collision shape successfully!")
	else:
		print("Could not find mesh: ", mesh_instance)
