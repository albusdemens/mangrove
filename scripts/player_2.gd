extends CharacterBody3D

enum State {FALLING, COLLECT_GEM_1, COLLECT_GEM_2, MOVE_TO_FISHING, FISHING, DONE}

var speed = 3.0
var current_state = State.FALLING
var target_y_pos = 1.55  # Box surface height

# Define your fixed gem and fishing locations here
var gem_1_position = Vector3(-0.071, 1.55, 0.95)  # Replace with actual position
var gem_2_position = Vector3(0.845, 1.55, 0.14)  # Replace with actual position
var fishing_position = Vector3(0.027, 0.208, 1.842)  # Replace with actual position

var current_target_position = Vector3.ZERO
var fishing_timer = 0.0
var fishing_duration = 3.0  # How long to fish in seconds

func _ready():
    print("NPC initialized, starting sequence")

func _physics_process(delta):
    match current_state:
        State.FALLING:
            # Handle falling with gravity
            velocity.y -= 9.8 * delta
            move_and_slide()
            
            # Check if we've landed on the surface
            if is_on_floor() or global_position.y <= target_y_pos:
                print("Landed on surface, moving to first gem")
                global_position.y = target_y_pos
                current_state = State.COLLECT_GEM_1
                current_target_position = gem_1_position
                
        State.COLLECT_GEM_1:
            move_to_target(delta)
            if global_position.distance_to(current_target_position) < 0.1:
                print("Reached first gem, moving to second gem")
                current_state = State.COLLECT_GEM_2
                current_target_position = gem_2_position
                
        State.COLLECT_GEM_2:
            move_to_target(delta)
            if global_position.distance_to(current_target_position) < 0.1:
                print("Reached second gem, moving to fishing spot")
                current_state = State.MOVE_TO_FISHING
                current_target_position = fishing_position
                
        State.MOVE_TO_FISHING:
            move_to_target(delta)
            if global_position.distance_to(current_target_position) < 0.1:
                print("Reached fishing spot, starting to fish")
                current_state = State.FISHING
                fishing_timer = 0.0
                
        State.FISHING:
            # Add fishing animation code here if you have one
            # e.g. $AnimationPlayer.play("fishing")
            
            fishing_timer += delta
            if fishing_timer >= fishing_duration:
                print("Finished fishing, found gem!")
                current_state = State.DONE
                
        State.DONE:
            # NPC has completed its task, do nothing or loop back
            pass

func move_to_target(delta):
    var direction = (current_target_position - global_position).normalized()
    direction.y = 0  # Keep movement on XZ plane
    
    velocity = direction * speed
    velocity.y = 0  # Lock Y movement
    move_and_slide()
    
    # Ensure Y position stays constant
    global_position.y = target_y_pos

func _on_body_entered(body):
    # Check if we collided with a resource
    if body.is_in_group("collectible"):
        print("Resource collected: ", body.name)
        body.queue_free()  # Make the resource disappear
        
        # You might want to add additional logic here
        # if you need to know specifically which gem was collected