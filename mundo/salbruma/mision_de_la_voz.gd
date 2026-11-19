class_name MisionDeLaVoz
extends Area3D
## Misión dorada "Desenmascara al impostor" (Documento Maestro, 9.3 y 9.4).
##
## Al entregar La última marea, La Voz la anuncia. Sigue activa durante toda la
## investigación de Puerto Albor y se cierra en intriga_de_albor.gd al vencer al
## profeta (9.7, encargo 7).
##
## PROVISIONAL: el documento no trae el texto de la visión; La Voz dice la
## descripción funcional de la misión.

const ROSTRO := preload("res://encargos/puerto_albor_rostro_del_engano.tres")

## Misión dorada de la investigación.
@export var mision: Encargo
## Encargo cuya entrega dispara la visión.
@export var desencadenante: Encargo

var _anunciando := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	Encargos.hito.connect(_al_cambiar_encargo)
	_restaurar_mision()
	if Encargos.estado_de(desencadenante) == Encargos.Estado.COMPLETADO:
		_anunciar.call_deferred()


func _restaurar_mision() -> void:
	# Las partidas del prototipo anterior cerraban la investigación al llegar.
	if Encargos.estado_de(mision) >= Encargos.Estado.CUMPLIDO and Encargos.estado_de(ROSTRO) < Encargos.Estado.CUMPLIDO:
		var datos := Encargos.a_diccionario()
		for registro: Dictionary in datos["encargos"]:
			if registro["id"] == String(mision.id):
				registro["estado"] = Encargos.Estado.ACTIVO
				registro["avance"] = 0
				registro["elementos"] = []
		Encargos.desde_diccionario(datos)


func _al_cambiar_encargo(encargo: Encargo, estado: int) -> void:
	if encargo == desencadenante and estado == Encargos.Estado.COMPLETADO:
		_anunciar()


func _anunciar() -> void:
	if _anunciando or not Encargos.puede_aceptar(mision):
		return
	_anunciando = true
	while Interfaz.ocupada():
		await get_tree().process_frame
	await Interfaz.dialogo.decir("La Voz", mision.oferta)
	Encargos.aceptar(mision)
	Interfaz.dialogo.cerrar()
	_anunciando = false
