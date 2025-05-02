extends Node

@onready var animation_player = $"../AnimationPlayer" if has_node("../AnimationPlayer") else null

func _ready():
	print("Auto Play Animation script running")
	if animation_player:
		print("AnimationPlayer found, animations: ", animation_player.get_animation_list())
		# Try to play the ZeppelinPass animation
		if animation_player.has_animation("ZeppelinPass"):
			print("Playing ZeppelinPass animation")
			animation_player.play("ZeppelinPass")
		else:
			# Try to play the first available animation if ZeppelinPass doesn't exist
			var animations = animation_player.get_animation_list()
			if animations.size() > 0:
				print("Playing first available animation: ", animations[0])
				animation_player.play(animations[0])
			else:
				print("No animations found in AnimationPlayer")
	else:
		print("AnimationPlayer not found")
