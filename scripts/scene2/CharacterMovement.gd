extends CharacterBody3D

@export var move_radius: float = 0.2
@export var move_speed: float = 0.5
@export var wait_time: float = 0.5

var origin_position: Vector3
var target_position: Vector3
var moving: bool = false
var wait_timer: float = 0.0

func _ready():
	origin_position = global_transform.origin
	pick_new_target()

func _physics_process(delta):
	if moving:
		var direction = (target_position - global_transform.origin)
		var distance = direction.length()
		if distance < 0.1:
			moving = false
			wait_timer = wait_time
		else:
			direction = direction.normalized()
			velocity = direction * move_speed
			move_and_slide()
	else:
		wait_timer -= delta
		if wait_timer <= 0.0:
			pick_new_target()

func pick_new_target():
	var random_offset = Vector3(
		randf_range(-move_radius, move_radius),
		0,
		randf_range(-move_radius, move_radius)
	)
	target_position = origin_position + random_offset
	moving = true
