extends Label

# Points count (same as coins)
var point_count: int = 0

func _ready():
	# Initialize text
	text = "Points: 0"
	
	# Make sure we're in a CanvasLayer for camera-independent rendering
	var parent = get_parent()
	if not parent is CanvasLayer:
		print("ResourceCounter: Not in a CanvasLayer, creating one...")
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100  # High layer to be on top
		canvas_layer.name = "ResourceCounterLayer"
		
		# Get current parent to reattach
		if parent:
			var current_pos = position
			parent.remove_child(self)
			get_tree().root.add_child(canvas_layer)
			canvas_layer.add_child(self)
			position = current_pos
		else:
			get_tree().root.add_child(canvas_layer)
			canvas_layer.add_child(self)
	
	# Ensure visibility and good positioning/styling
	visible = true
	size = Vector2(200, 60)
	position = Vector2(50, 50)
	
	# Add a custom font with larger size for better visibility
	add_theme_font_size_override("font_size", 24)
	
	# Set a contrasting color for visibility
	modulate = Color(1, 0.9, 0.2)  # Gold/yellow color
	
	# Force display to screen, try to overcome any viewport issues
	set_process(true)
	
	print("DEBUG: ResourceCounter initialized at path: " + str(get_path()))
	print("DEBUG: ResourceCounter parent is: " + str(get_parent().name))
	print("DEBUG: ResourceCounter visible: " + str(visible))
	print("DEBUG: ResourceCounter position: " + str(position))

func _process(_delta):
	# Ensure visibility every frame for debugging
	if not visible:
		visible = true
		print("DEBUG: ResourceCounter was invisible, making visible")

# Update point count (points and coins are the same)
func update_coin_count(new_count: int):
	point_count = new_count
	text = "Points: %d" % point_count
	# Force update visuals
	queue_redraw()
	print("DEBUG: ResourceCounter updated text to: '" + text + "'")