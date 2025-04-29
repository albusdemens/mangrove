extends Node3D

@export var constant_speed = 5.0
@export var movement_direction = Vector3(0, 0, -1) # Default: moving forward (adjust in Inspector)
var velocity = Vector3.ZERO
var is_crashed = false # Add this if you haven't already

func _physics_process(delta):
	if not is_crashed:
		velocity = movement_direction.normalized() * constant_speed
		translate(velocity * delta)

func _on_collision_shape_body_entered(body):
	if body.is_in_group("mountain"):
		is_crashed = true
		velocity = Vector3.ZERO
		# Add your camera switch and other crash logic here later
