extends Control

func _ready() -> void:
	HUD.visible = false
	await get_tree().create_timer(0.5).timeout
	var tween = create_tween()
	tween.tween_property($ColorRect, "color:a", 0.85, 1.0)

func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/initialGame.tscn")
