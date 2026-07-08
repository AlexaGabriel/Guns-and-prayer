extends CharacterBody2D

const PROJETIL = preload("res://projetil.tscn")

@export var speed: float = 60.0
@export var max_health: int = 5
@export var fire_rate: float = 0.35

@onready var _animated_sprite = $AnimatedSprite2D

var current_health: int
var _invincible: bool = false
var last_direction: Vector2 = Vector2(0, 1)
var _can_shoot: bool = true

var armas: Dictionary = {}
var arma_ativa: String = ""
var municao_atual: int = 0
var municao_maxima: int = 0

signal health_changed(new_health: int, max_health: int)
signal died
signal weapon_changed(weapon_name: String)

func _ready() -> void:
	current_health = max_health
	add_to_group("player")
	await get_tree().process_frame
	_init_HUD()

func _init_HUD() -> void:
	HUD.restaurar_armas(self)
	HUD.atualizar_vida(current_health, max_health)
	HUD.atualizar_arma(arma_ativa, municao_atual, municao_maxima)
	health_changed.connect(_on_health_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		HUD.salvar_armas(armas, arma_ativa, municao_atual, municao_maxima)

func _salvar_armas() -> void:
	HUD.salvar_armas(armas, arma_ativa, municao_atual, municao_maxima)

func _on_health_changed(new_health: int, _max_health: int) -> void:
	HUD.atualizar_vida(new_health, _max_health)

func coletar_arma(nome: String, max_mun: int, mun: int, desc: String = "") -> void:
	if not armas.has(nome):
		armas[nome] = {"max": max_mun, "atual": mun}
		if arma_ativa == "":
			arma_ativa = nome
			municao_atual = mun
			municao_maxima = max_mun
			if HUD and HUD.has_method("atualizar_arma"):
				HUD.atualizar_arma(arma_ativa, municao_atual, municao_maxima)
	else:
		armas[nome]["atual"] = min(armas[nome]["atual"] + mun, armas[nome]["max"])
		if arma_ativa == nome:
			municao_atual = armas[nome]["atual"]
			HUD.atualizar_arma(arma_ativa, municao_atual, municao_maxima)

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
	if not _can_shoot:
		return
	if arma_ativa == "":
		return
	if municao_atual <= 0:
		return
	
	_can_shoot = false
	municao_atual -= 1
	armas[arma_ativa]["atual"] = municao_atual
	HUD.atualizar_arma(arma_ativa, municao_atual, municao_maxima)
	
	var mouse_pos = get_global_mouse_position()
	var base_dir = (mouse_pos - global_position).normalized()
	
	if arma_ativa == "rose":
		var angles = [-0.35, 0.0, 0.35]
		for angle in angles:
			var dir = base_dir.rotated(angle)
			_spawn_projetil(dir, 1, 300.0)
	else:
		_spawn_projetil(base_dir, 1, 300.0)
	
	await get_tree().create_timer(fire_rate).timeout
	if is_instance_valid(self):
		_can_shoot = true

func _spawn_projetil(dir: Vector2, dmg: int, spd: float) -> void:
	var proj = PROJETIL.instantiate()
	proj.position = global_position + dir * 10
	proj.direction = dir
	proj.damage = dmg
	proj.speed = spd
	get_tree().current_scene.add_child(proj)

func recarregar() -> void:
	if arma_ativa == "":
		return
	municao_atual = municao_maxima
	armas[arma_ativa]["atual"] = municao_atual
	HUD.atualizar_arma(arma_ativa, municao_atual, municao_maxima)

func trocar_arma() -> void:
	if armas.size() < 2:
		return
	var chaves = armas.keys()
	if arma_ativa == chaves[0]:
		arma_ativa = chaves[1]
	else:
		arma_ativa = chaves[0]
	municao_atual = armas[arma_ativa]["atual"]
	municao_maxima = armas[arma_ativa]["max"]
	HUD.atualizar_arma(arma_ativa, municao_atual, municao_maxima)

func heal(amount: int) -> bool:
	if current_health >= max_health:
		return false
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)
	return true

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
	set_physics_process(false)
	_animated_sprite.modulate = Color(1, 0.2, 0.2)
	emit_signal("died")
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()

func update_sprite_animation(dir: Vector2) -> void:
	if dir != Vector2.ZERO:
		last_direction = dir
		if abs(dir.x) > abs(dir.y):
			_animated_sprite.play("walk-side")
			_animated_sprite.flip_h = dir.x < 0
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
