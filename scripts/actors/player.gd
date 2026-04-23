extends CharacterBody2D

@export var speed: float = 60.0 
@onready var _animated_sprite = $AnimatedSprite2D

var last_direction: Vector2 = Vector2(0, 1)

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = direction * speed
	move_and_slide()
	
	update_sprite_animation(direction)

func update_sprite_animation(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		last_direction = dir
		if abs(dir.x) > abs(dir.y):
			_animated_sprite.play("walk-side")
			_animated_sprite.flip_h = dir.x < 0
			
		else:
			if dir.y > 0:
				_animated_sprite.play("walk") 
			else:
				_animated_sprite.play("walk-back") 
				
	else:
		if abs(last_direction.x) > abs(last_direction.y):
			_animated_sprite.play("idle-side")
			_animated_sprite.flip_h = last_direction.x < 0
			
		else:
			if last_direction.y > 0:
				_animated_sprite.play("idle")
			else:
				_animated_sprite.play("idle-back") 
