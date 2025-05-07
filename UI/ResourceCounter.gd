extends Label

# Signal to update the resource count
signal update_count(new_count)

# Current resource count
var resource_count: int = 0 setget set_resource_count

# Function to set and update the resource count
func set_resource_count(new_count: int):
	resource_count = new_count
	text = "Coins: %d" % resource_count

# Function to update the coin count dynamically
func update_coin_count(new_count: int):
	resource_count = new_count
	emit_signal("update_count", resource_count)

default text = "Coins: 0"