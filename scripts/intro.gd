extends Control

var _current_panel: int = 0
var _panel_texts: Array[String] = [
	"Os demônios atacavam a cidade...\nO jornal da manhã não deixava dúvidas.",
	"O padre leu as manchetes com apreensão.\nEra seu dever proteger os inocentes.",
	"\"Que Deus me guie...\"\nEle pegou sua batina, sua pistola e seu rosário,\ne saiu para salvar o mundo."
]

@onready var _text_label: Label = $Panel/VBoxContainer/TextLabel
@onready var _next_button: Button = $Panel/VBoxContainer/NextButton
@onready var _skip_button: Button = $SkipButton

func _ready() -> void:
	HUD.visible = false
	_show_panel()

func _show_panel() -> void:
	if _current_panel < _panel_texts.size():
		_text_label.text = _panel_texts[_current_panel]
		if _current_panel >= _panel_texts.size() - 1:
			_next_button.text = "Começar"
	else:
		_start_game()

func _on_next_button_pressed() -> void:
	_current_panel += 1
	_show_panel()

func _on_skip_button_pressed() -> void:
	_start_game()

func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/HolyHouse.tscn")
