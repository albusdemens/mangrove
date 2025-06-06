# CollectibleResource.gd
extends Node3D

@export var points: int = 10
@export var is_crystal: bool = false

signal resource_collected(points, is_crystal)

var area: Area3D

func _ready():
	# Add to fishable_resource group if it's a flower (not crystal)
	if !is_crystal:
		add_to_group("fishable_resource")
		print("Flower added to fishable_resource group")
	
	if is_crystal:
		# Create static collision for crystals (can't pass through)
		var static_body = StaticBody3D.new()
		var collision_shape_static = CollisionShape3D.new()  # Different name
		var shape_static = BoxShape3D.new()  # Different name
		shape_static.size = Vector3(0.3, 0.3, 0.3)
		collision_shape_static.shape = shape_static
		static_body.add_child(collision_shape_static)
		static_body.collision_layer = 2
		add_child(static_body)
	
	# Create Area3D for detection (both flowers and crystals)
	area = Area3D.new()
	var collision_shape_area = CollisionShape3D.new()  # Different name
	var shape_area = BoxShape3D.new()  # Different name
	
	# Make collision shape smaller for more precise collection
	if is_crystal:
		shape_area.size = Vector3(0.3, 0.3, 0.3)
	else:
		shape_area.size = Vector3(0.2, 0.2, 0.2)
	
	collision_shape_area.shape = shape_area
	area.add_child(collision_shape_area)
	
	# Configure collision
	area.collision_layer = 2  # Resources layer
	area.collision_mask = 1   # Players layer
	# Connect signal
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _on_body_entered(body):
	if body.has_method("collect_resource"):
		body.collect_resource(points, is_crystal)
		emit_signal("resource_collected", points, is_crystal)  # Emit signal when collected
		if not is_crystal:  # Only flowers disappear
			queue_free()

# Called also by the fishing system when caught by the bobber
func collect(collector):
	if collector.has_method("collect_resource"):
		collector.collect_resource(points, is_crystal)
		
		# Special case for player_2 collecting crystals
		if is_crystal and collector.name == "Player2":
			queue_free()  # Make crystal disappear for player_2
		elif not is_crystal:  # Normal flower collection
			queue_free()
			
	print("Resource collected by: ", collector.name)
