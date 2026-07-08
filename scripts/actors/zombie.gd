extends CharacterBody2D

@export var speed: float = 35.0
@export var max_health: int = 3
@export var damage: int = 1
@export var detection_radius: float = 80.0
@export var attack_range: float = 18.0
@export var attack_cooldown: float = 1.2

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _detection_area: Area2D = $DetectionArea
@onready var _hit_timer: Timer = $HitTimer

var current_health: int
var _player: CharacterBody2D = null
var _can_attack: bool = true
var _is_dead: bool = false
var _is_staggered: bool = false
var _last_direction: Vector2 = Vector2(0, 1)

signal died

func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")
	await get_tree().process_frame
	_player = get_tree().root.find_child("Player", true, false)
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)
	_hit_timer.wait_time = attack_cooldown
	_hit_timer.one_shot = true
	_hit_timer.timeout.connect(_on_hit_timer_timeout)

func _physics_process(_delta: float) -> void:
	if _is_dead or _is_staggered:
		return
	if _player == null:
		_play_idle_animation()
		return

	_nav_agent.target_position = _player.global_position
	var dist = global_position.distance_to(_player.global_position)

	if dist <= attack_range:
		velocity = Vector2.ZERO
		_try_attack()
		# Empurra para o lado para não sobrepor outros inimigos
		_push_away_from_others()
	else:
		var next_pos = _nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity = direction * speed
		_last_direction = direction
		_play_walk_animation(direction)

	move_and_slide()

func _push_away_from_others() -> void:
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self:
			continue
		var d = global_position.distance_to(other.global_position)
		if d < 14.0 and d > 0.1:
			global_position += (global_position - other.global_position).normalized() * 1.5

func take_damage(amount: int) -> void:
	if _is_dead:
		return
	current_health -= amount
	if current_health <= 0:
		_die()
	else:
		_flash_damage()
		_start_stagger()

func _start_stagger() -> void:
	_is_staggered = true
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		_is_staggered = false

func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	emit_signal("died")
	var death = _animated_sprite.sprite_frames
	if death != null and death.has_animation("death") and death.get_frame_count("death") > 0:
		_animated_sprite.play("death")
		await _animated_sprite.animation_finished
	queue_free()

func _flash_damage() -> void:
	_animated_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		_animated_sprite.modulate = Color(1, 1, 1)

func _try_attack() -> void:
	if not _can_attack:
		return
	_can_attack = false
	_hit_timer.start()
	if _player.has_method("take_damage"):
		_player.take_damage(damage)

func _on_hit_timer_timeout() -> void:
	_can_attack = true

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		_player = body

func _on_body_exited(body: Node) -> void:
	pass

func _play_idle_animation() -> void:
	if _animated_sprite.sprite_frames == null:
		return
	var has_idle = _animated_sprite.sprite_frames.has_animation("idle")
	if not has_idle:
		return
	if abs(_last_direction.x) > abs(_last_direction.y):
		if _animated_sprite.sprite_frames.has_animation("idle-side"):
			_animated_sprite.play("idle-side")
		else:
			_animated_sprite.play("idle")
		_animated_sprite.flip_h = _last_direction.x < 0
	elif _last_direction.y > 0:
		_animated_sprite.play("idle")
	else:
		if _animated_sprite.sprite_frames.has_animation("idle-back"):
			_animated_sprite.play("idle-back")
		else:
			_animated_sprite.play("idle")

func _play_walk_animation(dir: Vector2) -> void:
	if _animated_sprite.sprite_frames == null:
		return
	if not _animated_sprite.sprite_frames.has_animation("idle"):
		return
	var walk = "walk" if _animated_sprite.sprite_frames.has_animation("walk") else "idle"
	if abs(dir.x) > abs(dir.y):
		var side = "walk-side" if _animated_sprite.sprite_frames.has_animation("walk-side") else walk
		_animated_sprite.play(side)
		_animated_sprite.flip_h = dir.x < 0
	elif dir.y > 0:
		_animated_sprite.play(walk)
	else:
		var back = "walk-back" if _animated_sprite.sprite_frames.has_animation("walk-back") else walk
		_animated_sprite.play(back)
