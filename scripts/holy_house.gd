extends Node2D

func _ready() -> void:
	HUD.visible = true
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("died"):
		player.died.connect(_on_player_died)

	var controls_help = get_node_or_null("CanvasLayer/ControlsHelp")
	if controls_help:
		await get_tree().create_timer(8.0).timeout
		if is_instance_valid(controls_help):
			controls_help.visible = false

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file("res://scenes/levels/room.tscn")

func _on_player_died() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/levels/death.tscn")
