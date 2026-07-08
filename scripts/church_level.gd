extends Node2D

@onready var _boss_bar_bg: ColorRect = $CanvasLayer/BossBarBg
@onready var _boss_bar_fill: ColorRect = $CanvasLayer/BossBarFill
@onready var _boss_label: Label = $CanvasLayer/BossLabel
@onready var _suspense_label: Label = $CanvasLayer/SuspenseLabel

var _boss_max_health: int = 300
var _bar_full_width: float = 0.0

func _ready() -> void:
	HUD.visible = true
	await get_tree().process_frame
	_bar_full_width = _boss_bar_bg.size.x - 4
	_boss_bar_bg.visible = false

	var bosses = get_tree().get_nodes_in_group("boss")
	for boss in bosses:
		if boss.has_signal("boss_died"):
			boss.boss_died.connect(_on_boss_died)
		if boss.has_signal("boss_damaged"):
			boss.boss_damaged.connect(_on_boss_damaged)
		_boss_max_health = boss.max_health

	_show_suspense()

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

func _show_suspense() -> void:
	_suspense_label.visible = true
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(_suspense_label):
		_suspense_label.visible = false
	if is_instance_valid(self):
		_boss_bar_bg.visible = true
		_boss_bar_fill.visible = true

func _on_boss_damaged(current_health: int, _max_health: int) -> void:
	if not _boss_bar_bg.visible:
		_boss_bar_bg.visible = true
		_boss_bar_fill.visible = true
	var ratio = float(current_health) / float(_boss_max_health)
	_boss_bar_fill.size.x = _bar_full_width * ratio

func _on_boss_died() -> void:
	_boss_bar_bg.visible = false
	_boss_bar_fill.visible = false
	_boss_label.text = "CHEFAO DERROTADO!"
	_boss_label.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/victory.tscn")

func _on_player_died() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/levels/death.tscn")
