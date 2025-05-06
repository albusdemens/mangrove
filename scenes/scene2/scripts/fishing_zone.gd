extends Area3D

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Add to group
	add_to_group("fishing_zones")

func _on_body_entered(body):
	# Check if it's the player
	if body.is_in_group("player"):
		print("Player entered fishing zone")
		body.enter_fishing_zone()

func _on_body_exited(body):
	# Check if it's the player
	if body.is_in_group("player"):
		print("Player exited fishing zone")
		body.exit_fishing_zone()
