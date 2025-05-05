# CollectibleResource.gd (verify this is working)
extends Node3D

@export var points: int = 10
@export var is_crystal: bool = false

var area: Area3D

func _ready():
	# Create Area3D for detection
	area = Area3D.new()
	add_child(area)
	
	# Add collision shape
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.5, 0.5, 0.5)
	collision_shape.shape = shape
	area.add_child(collision_shape)
	
	# Configure collision
	area.collision_layer = 2  # Resources layer
	area.collision_mask = 1   # Players layer
	
	# Connect signal
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("collect_resource"):
		body.collect_resource(points, is_crystal)
		queue_free()  # This makes the flower disappear
