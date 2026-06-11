extends CharacterBody2D

@export var speed: float = 60.0
@export var max_health: int = 5

@onready var _animated_sprite = $AnimatedSprite2D

var current_health: int
var last_direction: Vector2 = Vector2(0, 1)
var _invincible: bool = false

signal health_changed(new_health: int, max_health: int)
signal died

func _ready() -> void:
	current_health = max_health
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	update_sprite_animation(direction)

func take_damage(amount: int) -> void:
	if _invincible:
		return
	current_health -= amount
	current_health = max(current_health, 0)
	emit_signal("health_changed", current_health, max_health)
	_start_invincibility()
	if current_health <= 0:
		_die()
	else:
		_flash_damage()

func _flash_damage() -> void:
	_animated_sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		_animated_sprite.modulate = Color(1, 1, 1)

func _start_invincibility() -> void:
	_invincible = true
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(self):
		_invincible = false

func _die() -> void:
	emit_signal("died")
	# Aqui pode adicionar lógica de game over futuramente
	queue_free()

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
