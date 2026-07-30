extends CharacterBody2D

@export var movement_speed = 250
var character_direction : Vector2

func _physics_process(delta: float) -> void:
	character_direction.x = Input.get_axis("move left", "move right")
	character_direction.y = Input.get_axis("move up", "move down")
	
	#change the orientation of the characters sprite
	if character_direction.x > 0: %Sprite.flip_h = false
	elif character_direction.x > 0: %Sprite.flip_h = true
	
	#moves the character and sets animation to match current state
	if character_direction:
		velocity = character_direction * movement_speed
		if %Sprite.animation != "Walk": %Sprite.animation = "Walk"
	else: 
		velocity.move_toward(Vector2.ZERO, movement_speed)
		if %Sprite.animation != "Idle": %Sprite.animation = "Idle"
