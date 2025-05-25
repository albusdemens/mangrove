extends CharacterBody3D

@export var move_speed : float = 2
@export var info_screen_path : NodePath
@export var screen_offset_distance : float = 1.5
@export var flip_direction : bool = true
@export var pulse_dot: MeshInstance3D
@export var remote_info_screen: Node3D
@export var camera_rig: Node3D
@export var floating_choices: Node3D
@export var resource_a: MeshInstance3D
@export var resource_b: MeshInstance3D

var _info_screen : InfoScreen
var _tween : Tween
var mid_camera_position: Vector3
var mid_camera_look_at: Vector3

func _ready():
	_info_screen = get_node(info_screen_path) as InfoScreen

	var screen_transform = _info_screen.global_transform
	var forward_dir = -screen_transform.basis.z.normalized()
	if flip_direction:
		forward_dir = -forward_dir

	var screen_position = screen_transform.origin
	var target_position = screen_position + forward_dir * screen_offset_distance
	target_position.y = global_transform.origin.y
	
	# compute mid coords between screen positions for camera side view
	compute_mid_camera(_info_screen, remote_info_screen)

	# walk player character to screen
	walk_to_and_post(target_position)

func walk_to_and_post(target_position: Vector3):
	var distance := global_transform.origin.distance_to(target_position)
	var travel_time := distance / move_speed

	_tween = get_tree().create_tween()
	_tween.tween_property(self, "global_transform:origin", target_position, travel_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func():
		var floating_text = $FloatingText
		floating_text.start_typing()
		floating_text.connect("post_pressed", Callable(self, "_on_post_pressed"))
		floating_text.connect("message_sent", Callable(self, "_on_message_sent"))
	)

func _on_post_pressed():
	_info_screen.interact()
	
func _on_message_sent(from_pos: Vector3, to_pos: Vector3):
	await get_tree().create_timer(1.5).timeout
	start_pipe_pulse(from_pos, to_pos)
	swing_camera_to()

func start_pipe_pulse(from_pos: Vector3, to_pos: Vector3):
	if not pulse_dot:
		push_error("PulseDot not assigned!")
		return

	var start_z = from_pos.z
	var end_z = to_pos.z

	# ✅ Use PulseDot's initial X/Y (e.g., aligned with pipe geometry)
	var fixed_x = pulse_dot.global_transform.origin.x
	var fixed_y = pulse_dot.global_transform.origin.y

	var real_from = Vector3(fixed_x, fixed_y, start_z)
	var real_to = Vector3(fixed_x, fixed_y, end_z)

	pulse_dot.visible = true
	pulse_dot.global_transform.origin = real_from

	# Animate camera movement from start (screen a) to (screen b) - we swivel into side view and then behind screen b
	var tween = get_tree().create_tween()
	tween.tween_property(pulse_dot, "global_transform:origin", real_to, 2.5)
	tween.tween_callback(func():
		pulse_dot.visible = false
		remote_info_screen.interact()
		# ✅ Display floating choices for PlayerB
		floating_choices.show_choices()
		floating_choices.connect("choice_made", Callable(self, "_on_trade_response"))
	)
	
func compute_mid_camera(from_screen: Node3D, to_screen: Node3D, side_offset: float = 8.0, height: float = 3.0) -> void:
	var pos_a = from_screen.global_transform.origin
	var pos_b = to_screen.global_transform.origin

	var mid_point = (pos_a + pos_b) * 0.5
	mid_camera_look_at = mid_point

	# Compute a side offset perpendicular to the pipe direction
	var direction = (pos_b - pos_a).normalized()
	var side = direction.cross(Vector3.UP).normalized() * side_offset

	# Final camera position: offset to the side and raised up
	mid_camera_position = mid_point + side + Vector3(0, height, 0)
	
func swing_camera_to():
	if not camera_rig or not remote_info_screen:
		push_error("Camera rig or remote screen not assigned")
		return
	camera_rig.current = true

	var end_pos := remote_info_screen.global_transform.origin + Vector3(0, 0, -6)
	var end_look := remote_info_screen.global_transform.origin + Vector3(0, -0.5, 0)

	var tween = get_tree().create_tween()

	# Step 1: pan out to mid-view (side view)
	tween.tween_property(camera_rig, "global_transform:origin", mid_camera_position, 1.2)
	tween.parallel().tween_property(
		camera_rig, "global_transform:basis",
		Transform3D().looking_at(mid_camera_look_at - mid_camera_position, Vector3.UP).basis,
		1.2
	)

	# Step 2: move to remote board
	tween.tween_property(camera_rig, "global_transform:origin", end_pos, 1.2)
	tween.parallel().tween_property(
		camera_rig, "global_transform:basis",
		Transform3D().looking_at(end_look - end_pos, Vector3.UP).basis,
		1.2
	)
	
func swivel_camera_to_side():
	# Go into side view to observe both screens
	if not camera_rig:
		push_error("Camera rig not assigned")
		return

	var tween = get_tree().create_tween()
	tween.tween_property(camera_rig, "global_transform:origin", mid_camera_position, 1.0)
	tween.parallel().tween_property(
		camera_rig, "global_transform:basis",
		Transform3D().looking_at(mid_camera_look_at - mid_camera_position, Vector3.UP).basis,
		1.0
	)
	
func _on_trade_response(accepted: bool):
	if accepted:
		swivel_camera_to_side()
		await get_tree().create_timer(1.0).timeout  # wait before exchange
		start_resource_exchange()
	else:
		# (optional) show fade or denial message
		pass
		
func start_resource_exchange():
	if not resource_a or not resource_b:
		push_error("Resource models not assigned!")
		return

	var fromA = resource_a.global_transform
	var fromB = resource_b.global_transform

	var y_offset = -2
	# Start positions (centered below InfoScreenB and InfoScreenA)
	fromA.origin = remote_info_screen.global_transform.origin + Vector3(0, y_offset, 0)
	fromB.origin = _info_screen.global_transform.origin + Vector3(0, y_offset, 0)

	# End positions: send A to ScreenA, B to ScreenB
	var toA = _info_screen.global_transform.origin + Vector3(0, y_offset, 0)
	var toB = remote_info_screen.global_transform.origin + Vector3(0, y_offset, 0)

	resource_a.global_transform = fromA
	resource_b.global_transform = fromB
	resource_a.visible = true
	resource_b.visible = true

	var tween = get_tree().create_tween()
	tween.tween_property(resource_a, "global_transform:origin", toA, 2.5)
	tween.parallel().tween_property(resource_b, "global_transform:origin", toB, 2.5)

	tween.tween_callback(func():
		resource_a.visible = false
		resource_b.visible = false
	)
