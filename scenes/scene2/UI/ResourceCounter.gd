extends Label

var total_points = 0

func _ready():
	# Connect to the resource_collected signal from CollectibleResource
	var collectible_resources = get_tree().get_nodes_in_group("collectible_resources")
	for resource in collectible_resources:
		if resource.has_signal("resource_collected"):
			resource.connect("resource_collected", Callable(self, "_on_resource_collected"))

func _on_resource_collected(points, _is_crystal):
	total_points += points
	update_counter()

func update_counter():
	# Use self instead of counter_label since this script is attached to the Label
	text = str(total_points)

# Function to update the coin count display
func update_coin_count(count: int):
	total_points = count
	text = "Coins: " + str(count)
