extends CharacterBody2D

# --- Parâmetros exportáveis (ajuste em cada inimigo) ---
@export var speed: float = 40.0
@export var max_health: int = 3
@export var damage: int = 1
@export var detection_radius: float = 80.0
@export var attack_range: float = 10.0
@export var attack_cooldown: float = 1.0

# --- Nós internos ---
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _detection_area: Area2D = $DetectionArea
@onready var _hit_timer: Timer = $HitTimer

# --- Estado ---
var current_health: int
var _player: CharacterBody2D = null
var _can_attack: bool = true
var _is_dead: bool = false
var _last_direction: Vector2 = Vector2(0, 1)

# --- Sinais ---
signal died

func _ready() -> void:
	current_health = max_health
	_detection_area.get_node("CollisionShape2D").shape.radius = detection_radius
	_detection_area.body_entered.connect(_on_body_entered)
	_detection_area.body_exited.connect(_on_body_exited)
	_hit_timer.wait_time = attack_cooldown
	_hit_timer.one_shot = true
	_hit_timer.timeout.connect(_on_hit_timer_timeout)

func _physics_process(_delta: float) -> void:
	if _is_dead:
		return

	if _player == null:
		_play_idle_animation()
		return

	# Atualiza destino da navegação
	_nav_agent.target_position = _player.global_position

	# Verifica se está no alcance de ataque
	var dist = global_position.distance_to(_player.global_position)
	if dist <= attack_range:
		velocity = Vector2.ZERO
		_try_attack()
	else:
		# Move em direção ao player desviando obstáculos
		var next_pos = _nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		velocity = direction * speed
		_last_direction = direction
		_play_walk_animation(direction)

	move_and_slide()

# --- Dano ---
func take_damage(amount: int) -> void:
	if _is_dead:
		return
	current_health -= amount
	if current_health <= 0:
		_die()
	else:
		_flash_damage()

func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	_play_death_animation()
	emit_signal("died")
	# Remove o nó após a animação terminar
	await _animated_sprite.animation_finished
	queue_free()

func _flash_damage() -> void:
	_animated_sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	if is_instance_valid(self):
		_animated_sprite.modulate = Color(1, 1, 1)

# --- Ataque ---
func _try_attack() -> void:
	if not _can_attack:
		return
	_can_attack = false
	_hit_timer.start()
	if _player.has_method("take_damage"):
		_player.take_damage(damage)

func _on_hit_timer_timeout() -> void:
	_can_attack = true

# --- Detecção ---
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player = null

# --- Animações (sobrescreva nas subclasses se necessário) ---
func _play_idle_animation() -> void:
	if _animated_sprite.sprite_frames == null:
		return
	if abs(_last_direction.x) > abs(_last_direction.y):
		_animated_sprite.play("idle-side")
		_animated_sprite.flip_h = _last_direction.x < 0
	elif _last_direction.y > 0:
		_animated_sprite.play("idle")
	else:
		_animated_sprite.play("idle-back")

func _play_walk_animation(dir: Vector2) -> void:
	if _animated_sprite.sprite_frames == null:
		return
	if abs(dir.x) > abs(dir.y):
		_animated_sprite.play("walk-side")
		_animated_sprite.flip_h = dir.x < 0
	elif dir.y > 0:
		_animated_sprite.play("walk")
	else:
		_animated_sprite.play("walk-back")

func _play_death_animation() -> void:
	if _animated_sprite.sprite_frames == null:
		return
	if _animated_sprite.sprite_frames.has_animation("death"):
		_animated_sprite.play("death")
