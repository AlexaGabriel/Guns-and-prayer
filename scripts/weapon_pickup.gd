extends Area2D

@export var weapon_name: String = "pistola"
@export var max_ammo: int = 12
@export var ammo: int = 12
@export var description: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("coletar_arma"):
		body.coletar_arma(weapon_name, max_ammo, ammo, description)
		queue_free()
