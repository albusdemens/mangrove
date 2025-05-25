extends Label3D

@export var message : String = "Do you want to trade resources? 💎"
@export var char_delay : float = 0.04
@export var post_delay : float = 0.5
@export var post_sound : AudioStream
@export var local_info_screen: Node3D
@export var remote_info_screen: Node3D

signal post_pressed
signal message_sent(from_pos: Vector3, to_pos: Vector3)

var _char_index := 0
var _typing_timer : Timer
var _post_timer : Timer
var _post_button : MeshInstance3D
var _sound_player : AudioStreamPlayer3D

func _ready():
	text = ""
	_typing_timer = Timer.new()
	_typing_timer.wait_time = char_delay
	_typing_timer.one_shot = false
	_typing_timer.timeout.connect(_type_next_char)
	add_child(_typing_timer)

	_post_timer = Timer.new()
	_post_timer.wait_time = post_delay
	_post_timer.one_shot = true
	_post_timer.timeout.connect(_press_post)
	add_child(_post_timer)

	_post_button = $PostButton
	_post_button.visible = false

	_sound_player = AudioStreamPlayer3D.new()
	_sound_player.stream = post_sound
	add_child(_sound_player)

func start_typing(new_message: String = ""):
	if new_message != "":
		message = new_message
	_char_index = 0
	text = ""
	_post_button.visible = true
	var mat := _post_button.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(1, 1, 1, 0.3)  # dim while typing
	_typing_timer.start()

func _type_next_char():
	if _char_index < message.length():
		text += message[_char_index]
		_char_index += 1
	else:
		_typing_timer.stop()
		var mat := _post_button.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(1, 1, 1, 1.0)  # brighten to active
		_post_timer.start()

func _press_post():
	var original_pos = _post_button.transform.origin
	var pressed_pos = original_pos + Vector3(0, -0.05, 0)
	var original_scale = _post_button.scale

	var press_tween = get_tree().create_tween()

	# Press animation
	press_tween.tween_property(_post_button, "transform:origin", pressed_pos, 0.1)
	press_tween.tween_property(_post_button, "transform:origin", original_pos, 0.1)
	press_tween.tween_property(_post_button, "scale", original_scale * 0.95, 0.1)
	press_tween.tween_property(_post_button, "scale", original_scale, 0.1)

	# Fade out the FloatingText and button
	press_tween.tween_interval(0.2)
	press_tween.tween_property(self, "scale", Vector3.ONE * 1.0, 0.1)
	press_tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	press_tween.tween_callback(func():
		self.visible = false
	)

	#_sound_player.play()
	press_tween.tween_callback(emit_post)
	
func emit_post():
	emit_signal("post_pressed")
	emit_signal("message_sent", local_info_screen.global_transform.origin, remote_info_screen.global_transform.origin)
