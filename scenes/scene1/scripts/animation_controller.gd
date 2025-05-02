extends Node

@onready var zeppelin_pass = $"../ZeppelinPass"
@onready var zeppelin_crash = $"../ZeppelinCrash"

func _ready():
	# Stop all animations first to make sure nothing plays automatically
	zeppelin_pass.stop()
	zeppelin_crash.stop()
	
	# Play the ZeppelinCrash animation
	zeppelin_crash.play("ZeppelinCrash/ZeppelinCrashAnim")
	
	# If you want to switch between animations, you can uncomment this line instead
	#zeppelin_pass.play("ZeppelinPass")
