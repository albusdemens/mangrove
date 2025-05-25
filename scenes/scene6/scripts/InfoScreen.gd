extends Node3D
class_name InfoScreen

@export var newspaper_texture : Texture2D
@export var posting_texture  : Texture2D
@export var interaction_sound : AudioStream
@export var animation_time : float = 0.4

var _screen_mesh : MeshInstance3D
var _sound_player : AudioStreamPlayer3D  # Post Sound Effect: https://freesound.org/people/LittleRobotSoundFactory/sounds/270404/
var _tween : Tween
var _emission_energy := 0.2

func _ready():
	# Get the child mesh directly
	_screen_mesh = $ScreenMesh as MeshInstance3D

	# Set up a basic material
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = newspaper_texture
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy = 0.2
	mat.uv1_scale = Vector3(3.0, 2.0, 1.0)
	_screen_mesh.material_override = mat

	# Set up sound
	_sound_player = AudioStreamPlayer3D.new()
	add_child(_sound_player)
	_sound_player.stream = interaction_sound

func set_emission_energy(value):
	_emission_energy = value
	if _screen_mesh and _screen_mesh.material_override:
		_screen_mesh.material_override.emission_energy = _emission_energy

func interact():
	if not _screen_mesh or not _screen_mesh.material_override:
		push_error("Missing material")
		return

	_sound_player.play()

	_tween = get_tree().create_tween()
	_tween.tween_method(self.set_emission_energy, 0.2, 4.0, animation_time)
	_tween.tween_interval(0.05)
	_tween.tween_method(self.set_emission_energy, 4.0, 0.2, animation_time)
	_tween.tween_callback(_on_interaction_complete)

func _on_interaction_complete():
	_screen_mesh.material_override.albedo_texture = posting_texture
