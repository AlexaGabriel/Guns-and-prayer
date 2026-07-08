extends Node2D

@onready var _enemies_container: Node2D = $Enemies
@onready var _objective_label: Label = $CanvasLayer/ObjectiveLabel

var _all_dead: bool = false

func _ready() -> void:
	HUD.visible = true
	for enemy in _enemies_container.get_children():
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

func _on_enemy_died() -> void:
	if _all_dead:
		return
	await get_tree().process_frame
	_check_all_dead()

func _check_all_dead() -> void:
	for enemy in _enemies_container.get_children():
		if is_instance_valid(enemy):
			return

	_all_dead = true
	_objective_label.text = "Inimigos derrotados! Indo para a igreja..."
	_objective_label.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/church.tscn")

func _on_player_died() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/levels/death.tscn")
