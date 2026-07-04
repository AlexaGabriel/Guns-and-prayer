extends CanvasLayer

@onready var label_municao = $MarginContainer/PanelContainer/HBoxContainer/Label
@onready var icone_pistola = $MarginContainer/PanelContainer/HBoxContainer/IconePistola
@onready var icone_rose = $MarginContainer/PanelContainer/HBoxContainer/IconeRose

func atualizar_municao(atual: int, maxima: int):
	label_municao.text = str(atual) + "/" + str(maxima)

func atualizar_icones(arma_ativa: String):
	# Deixa a arma ativa brilhante (1.0) e a inativa transparente (0.3)
	if arma_ativa == "pistola":
		icone_pistola.modulate = Color(1, 1, 1, 1)
		icone_rose.modulate = Color(1, 1, 1, 0.3)
	else:
		icone_pistola.modulate = Color(1, 1, 1, 0.3)
		icone_rose.modulate = Color(1, 1, 1, 1)
