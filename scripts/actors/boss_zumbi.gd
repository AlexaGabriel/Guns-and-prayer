extends CharacterBody2D

@export var move_speed: float = 70.0
@export var attack_range: float = 42.0
@export var attack_damage: int = 3
@export var attack_cooldown: float = 1.2
@export var max_health: int = 50

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer

const WALK_ANIMS := {
	"Frente":   "AndandoFrente",
	"Costas":   "AndandoCostas",
	"Esquerda": "AndandoEsquerda",
	"Direita":  "AndandoDireita",
}

const ATTACK_ANIMS := {
	"Frente":   "Bater de Frente",
	"Costas":   "BaterCostas",
	"Esquerda": "Bater de Esquerda",
	"Direita":  "Bater de Direita",
}

var health: int
var player: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var current_direction: String = "Frente"

signal boss_died
signal boss_damaged(current_health: int, max_health: int)


func _ready() -> void:
	health = max_health
	add_to_group("boss")

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(_delta: float) -> void:
	if player == null or health <= 0:
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	current_direction = get_direction_name(to_player)

	if distance > attack_range:
		velocity = to_player.normalized() * move_speed
		move_and_slide()
		play_walk_animation(current_direction)
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		if can_attack:
			start_attack(current_direction)


func get_direction_name(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "Direita" if vec.x > 0.0 else "Esquerda"
	else:
		return "Frente" if vec.y > 0.0 else "Costas"


func play_walk_animation(direction: String) -> void:
	var anim_name: String = WALK_ANIMS[direction]
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)


func start_attack(direction: String) -> void:
	is_attacking = true
	can_attack = false

	var anim_name: String = ATTACK_ANIMS[direction]
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		sprite.play(WALK_ANIMS[direction])

	sprite.modulate = Color(1, 0.4, 0.2, 1)
	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self): return
	sprite.modulate = Color(1, 1, 1, 1)
	
	deal_damage()
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(self):
		is_attacking = false
		attack_timer.start()


func deal_damage() -> void:
	if player == null or health <= 0:
		return
	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_range + 10 and player.has_method("take_damage"):
		player.take_damage(attack_damage)


func _on_attack_timer_timeout() -> void:
	can_attack = true


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)
	boss_damaged.emit(health, max_health)
	if health <= 0:
		die()


func die() -> void:
	health = 0
	is_attacking = false
	set_physics_process(false)
	boss_died.emit()
	queue_free()
