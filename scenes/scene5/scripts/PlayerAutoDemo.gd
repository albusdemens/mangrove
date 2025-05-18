extends CharacterBody3D

@export var move_speed : float = 2.5
@export var info_screen_path : NodePath
@export var screen_offset_distance : float = 1.5
@export var flip_direction : bool = true

var _info_screen : InfoScreen
var _tween : Tween

func _ready():
	_info_screen = get_node(info_screen_path) as InfoScreen

	var screen_transform = _info_screen.global_transform
	var forward_dir = -screen_transform.basis.z.normalized()
	if flip_direction:
		forward_dir = -forward_dir

	var screen_position = screen_transform.origin
	var target_position = screen_position + forward_dir * screen_offset_distance
	target_position.y = global_transform.origin.y

	walk_to_and_post(target_position)

func walk_to_and_post(target_position: Vector3):
	var distance := global_transform.origin.distance_to(target_position)
	var travel_time := distance / move_speed

	_tween = get_tree().create_tween()
	_tween.tween_property(self, "global_transform:origin", target_position, travel_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(func():
		var floating_text = $FloatingText
		floating_text.start_typing("Posting update: City Status - GREEN")
		floating_text.connect("post_pressed", Callable(self, "_on_post_pressed"))
	)

func _on_post_pressed():
	_info_screen.interact()
