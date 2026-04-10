extends CharacterBody2D

@export var speed: float = 90.0
@onready var _animated_sprite = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = direction * speed
	move_and_slide()
	
	update_sprite_animation(direction)

func update_sprite_animation(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		if abs(dir.x) > abs(dir.y):
			_animated_sprite.play("walk" if dir.x > 0 else "walk")
		else:
			_animated_sprite.play("walk" if dir.y > 0 else "walk")
	else:
		_animated_sprite.play("idle")
