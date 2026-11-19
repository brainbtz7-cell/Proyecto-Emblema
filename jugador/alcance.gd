extends Area3D
## Detecta lo que el protagonista tiene a mano y lo usa al pulsar "interactuar".
##
## Si hay varias cosas cerca, elige la más cercana y muestra su acción en pantalla.

var _a_mano: Interactuable

@onready var _jugador: Jugador = owner


func _ready() -> void:
	collision_layer = 0
	collision_mask = Interactuable.CAPA


func _physics_process(_delta: float) -> void:
	_a_mano = _mas_cercano()
	Interfaz.mostrar_aviso(_a_mano.accion if _a_mano else "")


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("interactuar") and _a_mano and not Interfaz.ocupada():
		get_viewport().set_input_as_handled()
		_a_mano.usar(_jugador)


func _mas_cercano() -> Interactuable:
	if Interfaz.ocupada():
		return null
	var mejor: Interactuable = null
	var menor_distancia := INF
	for zona in get_overlapping_areas():
		var candidato := zona as Interactuable
		if candidato == null or not candidato.disponible:
			continue
		var distancia := global_position.distance_squared_to(candidato.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mejor = candidato
	return mejor
