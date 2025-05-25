extends Node3D

signal choice_made(accepted: bool)

@export var accept_button: MeshInstance3D
@export var decline_button: MeshInstance3D
@export var click_sound: AudioStream
@export var auto_accept_delay: float = 1.5  # seconds until fake click

var _sound_player: AudioStreamPlayer3D

func _ready():
	self.visible = false

	_sound_player = AudioStreamPlayer3D.new()
	_sound_player.stream = click_sound
	add_child(_sound_player)

func show_choices():
	self.visible = true
	accept_button.visible = true
	decline_button.visible = true

	await get_tree().create_timer(auto_accept_delay).timeout
	_fake_accept_click()

func _fake_accept_click():
	_sound_player.play()
	animate_button(accept_button)
	await get_tree().create_timer(1.5).timeout  # ← small pause after click
	emit_signal("choice_made", true)
	self.visible = false

func animate_button(button: MeshInstance3D):
	var origin = button.transform.origin
	var scale = button.scale

	var tween = get_tree().create_tween()
	tween.tween_property(button, "transform:origin", origin + Vector3(0, -0.05, 0), 0.1)
	tween.tween_property(button, "transform:origin", origin, 0.1)
	tween.tween_property(button, "scale", scale * 0.95, 0.1)
	tween.tween_property(button, "scale", scale, 0.1)
