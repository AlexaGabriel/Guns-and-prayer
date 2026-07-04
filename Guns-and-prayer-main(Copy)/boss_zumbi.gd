extends CharacterBody2D

# ===========================================================
# ÁRVORE DE NÓS ESPERADA (igual à sua imagem):
#
# Boss Zumbi (CharacterBody2D)  <- este script vai aqui
#   ├─ AnimatedSprite2D
#   ├─ CollisionShape2D          (colisão do corpo, pra colidir com o mundo)
#   ├─ Hitbox (Area2D)           (área que detecta o jogador pro ataque)
#   │    └─ CollisionShape2D
#   └─ AttackTimer (Timer)       (você precisa adicionar este node)
# ===========================================================

# ---------------------------------------------------------
# CONFIGURAÇÃO
# ---------------------------------------------------------
@export var move_speed: float = 70.0
@export var attack_range: float = 42.0      # distância pra parar de andar e atacar
@export var attack_damage: int = 20
@export var attack_cooldown: float = 1.2    # tempo entre ataques
@export var max_health: int = 300

# ---------------------------------------------------------
# NÓS
# ---------------------------------------------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var attack_timer: Timer = $AttackTimer

# ---------------------------------------------------------
# MAPEAMENTO DE ANIMAÇÕES
# (nomes exatamente como estão no seu SpriteFrames)
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# ESTADO
# ---------------------------------------------------------
var health: int
var player: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var current_direction: String = "Frente"

signal boss_died
signal boss_damaged(current_health: int, max_health: int)


func _ready() -> void:
	health = max_health

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("BossZumbi: nenhum nó no grupo 'player' foi encontrado.")

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# a Hitbox só precisa avisar quando o jogador entra/sai,
	# a checagem de dano em si é feita em deal_damage_if_in_range()
	hitbox.monitoring = true


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
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func start_attack(direction: String) -> void:
	is_attacking = true
	can_attack = false

	var anim_name: String = ATTACK_ANIMS[direction]
	sprite.play(anim_name)

	# espera a animação de ataque terminar antes de aplicar o dano.
	# se quiser o dano no meio do golpe (mais realista), troque por
	# um Timer com metade da duração da animação.
	await sprite.animation_finished

	deal_damage_if_in_range()
	is_attacking = false
	attack_timer.start()


# usa a Area2D "Hitbox" pra ver quem está dentro do alcance na hora do golpe
func deal_damage_if_in_range() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(attack_damage)


func _on_attack_timer_timeout() -> void:
	can_attack = true


# ---------------------------------------------------------
# DANO / MORTE DO BOSS
# ---------------------------------------------------------
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	boss_damaged.emit(health, max_health)
	if health <= 0:
		die()


func die() -> void:
	health = 0
	is_attacking = false
	set_physics_process(false)
	boss_died.emit()
	# se tiver animação de morte:
	# sprite.play("Morrer"); await sprite.animation_finished
	queue_free()
