extends Area3D
## Zona de un poblado. Cuando el protagonista entra, la fauna de los
## alrededores se repone.

## Capa de física del protagonista (la número 2, "jugador").
const CAPA_DEL_JUGADOR := 2


func _ready() -> void:
	collision_layer = 0
	collision_mask = CAPA_DEL_JUGADOR
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node3D) -> void:
	if cuerpo is Jugador:
		get_tree().call_group("manadas", "reponer")
