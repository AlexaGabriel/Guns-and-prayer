extends CanvasLayer

@onready var _vida_container: HBoxContainer = $PanelContainer/VBoxContainer/VidaContainer
@onready var _arma_label: Label = $PanelContainer/VBoxContainer/ArmaLabel
@onready var _municao_label: Label = $PanelContainer/VBoxContainer/MunicaoLabel

func atualizar_vida(atual: int, _maxima: int) -> void:
	if not _vida_container:
		return
	for child in _vida_container.get_children():
		child.queue_free()
	for i in range(atual):
		var heart = Label.new()
		heart.text = "♥"
		heart.add_theme_font_size_override("font_size", 14)
		heart.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
		_vida_container.add_child(heart)

func atualizar_arma(nome: String, atual: int, maxima: int) -> void:
	if not _arma_label or not _municao_label:
		return
	if nome == "":
		_arma_label.text = "Sem arma"
		_municao_label.text = ""
		_municao_label.visible = false
		_arma_label.visible = true
		return
	_arma_label.visible = true
	_municao_label.visible = true
	var nome_exibicao = "Pistola" if nome == "pistola" else "Rosario"
	if atual <= 0:
		_arma_label.text = nome_exibicao + " (SEM MUNICAO)"
	else:
		_arma_label.text = nome_exibicao
	_municao_label.text = str(atual) + " / " + str(maxima)
