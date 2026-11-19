class_name MisionDeLaVoz
extends Area3D
## Misión dorada "Desenmascara al impostor" (Documento Maestro, 9.3 y 9.4).
##
## Al entregar La última marea, La Voz da la misión. Al llegar a esta zona
## (Puerto Albor) se cumple el tramo del viaje.
##
## PROVISIONAL: el documento no trae el texto de la visión; La Voz dice solo la
## descripción funcional de la misión. La investigación en Albor (encargos,
## profeta) todavía no está hecha, así que el encargo se cierra al llegar.

## Capa de física del protagonista (la número 2, "jugador").
const CAPA_DEL_JUGADOR := 2

@export var mision: Encargo
## Encargo cuya entrega dispara la visión de La Voz.
@export var desencadenante: Encargo


func _ready() -> void:
	collision_layer = 0
	collision_mask = CAPA_DEL_JUGADOR
	body_entered.connect(_al_entrar)
	Encargos.hito.connect(_al_cambiar_encargo)


func _al_cambiar_encargo(encargo: Encargo, estado: int) -> void:
	if encargo != desencadenante or estado != Encargos.Estado.COMPLETADO or mision == null:
		return
	# Espera a que se cierre el diálogo de la entrega anterior.
	while Interfaz.ocupada():
		await get_tree().process_frame
	await Interfaz.dialogo.decir("La Voz", mision.oferta)
	Interfaz.dialogo.cerrar()
	if Encargos.puede_aceptar(mision):
		Encargos.aceptar(mision)


func _al_entrar(cuerpo: Node3D) -> void:
	if not cuerpo is Jugador or mision == null:
		return
	if Encargos.estado_de(mision) != Encargos.Estado.ACTIVO:
		return
	Encargos.contar(mision.clave_de_conteo)
	Encargos.entregar(mision)
	if not mision.cierre.is_empty():
		await Interfaz.dialogo.decir("", mision.cierre)
		Interfaz.dialogo.cerrar()
