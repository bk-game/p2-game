extends CharacterBody2D

@export var movement_speed: float = 500
var character_direction : Vector2

func _physics_process(_delta):
	character_direction.x = Input.get_axis("move_left", "move_right")
	character_direction.y = Input.get_axis("move_up", "move_down")
	
	#character direction
	if character_direction.x > 0 : %Sprite.flip_h = false
	elif character_direction.x < 0: %Sprite.flip_h = true
	
	
	if character_direction:
		#move player according to directional input
		velocity = character_direction * movement_speed 
		#sets the animation to walking when moving
		if %Sprite.animation != "Walk": %Sprite.animation = "Walk"
	else:
		#stops the player
		velocity = velocity.move_toward(Vector2.ZERO, movement_speed)
		#sets animation to idle
		if %Sprite.animation != "Idle": %Sprite.animation = "Idle"
		
	move_and_slide()
