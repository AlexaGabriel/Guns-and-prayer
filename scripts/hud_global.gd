extends CanvasLayer

var _panel: PanelContainer
var _vida_container: HBoxContainer
var _arma_label: Label
var _municao_label: Label

var armas_guardadas: Dictionary = {}
var arma_ativa_guardada: String = ""
var municao_atual_guardada: int = 0
var municao_maxima_guardada: int = 0

func _ready() -> void:
	layer = 10
	_setup_hud()

func _setup_hud() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 8.0
	_panel.offset_top = 8.0
	_panel.offset_right = 155.0
	_panel.offset_bottom = 75.0
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.0, 0.0, 0.82)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.7, 0.55, 0.05, 1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_vida_container = HBoxContainer.new()
	_vida_container.add_theme_constant_override("separation", 1)
	vbox.add_child(_vida_container)

	_arma_label = Label.new()
	_arma_label.text = "Sem arma"
	_arma_label.add_theme_font_size_override("font_size", 13)
	_arma_label.add_theme_color_override("font_color", Color(1, 1, 0.85, 1))
	vbox.add_child(_arma_label)

	_municao_label = Label.new()
	_municao_label.text = ""
	_municao_label.visible = false
	_municao_label.add_theme_font_size_override("font_size", 12)
	_municao_label.add_theme_color_override("font_color", Color(1, 1, 0.6, 1))
	vbox.add_child(_municao_label)

func atualizar_vida(atual: int, _maxima: int) -> void:
	for child in _vida_container.get_children():
		child.queue_free()
	for i in range(atual):
		var heart = Label.new()
		heart.text = "♥"
		heart.add_theme_font_size_override("font_size", 16)
		heart.add_theme_color_override("font_color", Color(1, 0.15, 0.15, 1))
		_vida_container.add_child(heart)

func atualizar_arma(nome: String, atual: int, maxima: int) -> void:
	if nome == "":
		_arma_label.text = "Sem arma"
		_municao_label.text = ""
		_municao_label.visible = false
		return
	_arma_label.visible = true
	_municao_label.visible = true
	var nome_exibicao = "Pistola" if nome == "pistola" else "Rosario"
	if atual <= 0:
		_arma_label.text = nome_exibicao + " (sem municao)"
	else:
		_arma_label.text = nome_exibicao
	_municao_label.text = str(atual) + " / " + str(maxima)

func salvar_armas(armas: Dictionary, ativa: String, muni: int, max_muni: int) -> void:
	armas_guardadas = armas.duplicate(true)
	arma_ativa_guardada = ativa
	municao_atual_guardada = muni
	municao_maxima_guardada = max_muni

func restaurar_armas(player) -> void:
	if arma_ativa_guardada != "":
		player.armas = armas_guardadas.duplicate(true)
		player.arma_ativa = arma_ativa_guardada
		player.municao_atual = municao_atual_guardada
		player.municao_maxima = municao_maxima_guardada
		atualizar_arma(arma_ativa_guardada, municao_atual_guardada, municao_maxima_guardada)
