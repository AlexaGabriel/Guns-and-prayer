extends CharacterBody2D

@export var speed: float = 60.0
@export var max_health: int = 5

@onready var _animated_sprite = $AnimatedSprite2D
@onready var hud = get_tree().current_scene.find_child("CanvasLayer", true, false)

var current_health: int
var _invincible: bool = false
var last_direction: Vector2 = Vector2(0, 1)

# Sistema de Armas
var armas = {
	"pistola": {"max": 12, "atual": 12},
	"rose": {"max": 6, "atual": 6}
}
var arma_ativa: String = "pistola"
var municao_atual: int = 12
var municao_maxima: int = 12

signal health_changed(new_health: int, max_health: int)
signal died

func _ready() -> void:
	current_health = max_health
	add_to_group("player")
	# Inicializa HUD com valores e ícones corretos
	if hud and hud.has_method("atualizar_municao"):
		hud.atualizar_municao(municao_atual, municao_maxima)
	if hud and hud.has_method("atualizar_icones"):
		hud.atualizar_icones(arma_ativa)

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	update_sprite_animation(direction)
	
	if Input.is_action_just_pressed("atirar"):
		atirar()
	
	if Input.is_action_just_pressed("recarregar"):
		recarregar()
		
	if Input.is_action_just_pressed("trocar_arma"):
		trocar_arma()

func atirar() -> void:
	if municao_atual > 0:
		municao_atual -= 1
		armas[arma_ativa]["atual"] = municao_atual
		if hud and hud.has_method("atualizar_municao"):
			hud.atualizar_municao(municao_atual, municao_maxima)
	else:
		print("Sem munição!")

func recarregar() -> void:
	municao_atual = municao_maxima
	armas[arma_ativa]["atual"] = municao_atual
	if hud and hud.has_method("atualizar_municao"):
		hud.atualizar_municao(municao_atual, municao_maxima)
	print("Recarregado!")

func trocar_arma() -> void:
	# Alterna o estado
	arma_ativa = "rose" if arma_ativa == "pistola" else "pistola"
	
	# Puxa os dados da arma selecionada
	municao_atual = armas[arma_ativa]["atual"]
	municao_maxima = armas[arma_ativa]["max"]
	
	# Atualiza munição e os ícones visuais na HUD
	if hud and hud.has_method("atualizar_municao"):
		hud.atualizar_municao(municao_atual, municao_maxima)
	if hud and hud.has_method("atualizar_icones"):
		hud.atualizar_icones(arma_ativa)
		
	print("Arma trocada para: ", arma_ativa)

func take_damage(amount: int) -> void:
	if _invincible: return
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health, max_health)
	_start_invincibility()
	if current_health <= 0: _die()
	else: _flash_damage()

func _flash_damage() -> void:
	_animated_sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self): _animated_sprite.modulate = Color(1, 1, 1)

func _start_invincibility() -> void:
	_invincible = true
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(self): _invincible = false

func _die() -> void:
	emit_signal("died")
	queue_free()

func update_sprite_animation(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		last_direction = dir
		if abs(dir.x) > abs(dir.y):
			_animated_sprite.play("walk-side")
			_animated_sprite.flip_h = dir.x < 0
		else:
			_animated_sprite.play("walk") if dir.y > 0 else _animated_sprite.play("walk-back")
	else:
		if abs(last_direction.x) > abs(last_direction.y):
			_animated_sprite.play("idle-side")
			_animated_sprite.flip_h = last_direction.x < 0
		else:
			_animated_sprite.play("idle") if last_direction.y > 0 else _animated_sprite.play("idle-back")
