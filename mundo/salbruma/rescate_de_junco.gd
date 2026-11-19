extends Node3D
## El jefe vuelve siguiendo las huellas del protagonista hasta que entran en Junco.

const EMBOSCADA := preload("res://encargos/puerto_junco_guardia_emboscada.tres")
const RESCATE := preload("res://encargos/puerto_junco_tablon_rescate.tres")

@export var jugador: Jugador
@export var jefe_de_junco: DadorDeEncargos
@export var poblado: Area3D

var _huellas: Array[Vector3] = []
var _ultima := Vector3.ZERO
var _siguiendo := false

@onready var _jefe: Node3D = $Jefe
@onready var _aviso: Label3D = $Aviso
@onready var _zona: Interactuable = $Interactuable
@onready var _volumen: BoxShape3D = poblado.get_node("Forma").shape


func _ready() -> void:
	_zona.usado.connect(_liberar)
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func _actualizar() -> void:
	var secuestrado := Encargos.avance_de(EMBOSCADA) > 0 and Encargos.estado_de(RESCATE) != Encargos.Estado.COMPLETADO
	var activo := Encargos.estado_de(RESCATE) == Encargos.Estado.ACTIVO
	var libre := Encargos.contado(RESCATE, &"liberar")
	jefe_de_junco.establecer_presencia(not secuestrado)
	_jefe.visible = secuestrado
	_zona.disponible = activo and not libre
	_aviso.visible = _zona.disponible
	if activo and libre and not _siguiendo:
		_ultima = jugador.global_position
		_huellas.clear()
		_huellas.append(_ultima)
		_siguiendo = true
	elif not activo:
		_siguiendo = false


func _liberar(_quien: Jugador) -> void:
	if not _zona.disponible:
		return
	Encargos.contar(RESCATE.clave_de_conteo, &"liberar")
	await Interfaz.dialogo.decir("Jefe pesquero", "Volvamos a Puerto Junco. Te sigo.")
	Interfaz.dialogo.cerrar()


func _physics_process(delta: float) -> void:
	if not _siguiendo:
		return
	var posicion := jugador.global_position
	var paso := _ultima.distance_to(posicion)
	if paso > 7.0:
		# El retorno desde el agua honda y la recarga reinician el rastro.
		_jefe.global_position = posicion + jugador.global_basis.z * 1.8
		_huellas.clear()
		_ultima = posicion
	elif paso > 0.43:
		_huellas.append(posicion)
		_ultima = posicion

	if _huellas.size() > 4:
		var objetivo := _huellas[0]
		var hacia := objetivo - _jefe.global_position
		if Vector2(hacia.x, hacia.z).length() > 0.06:
			_jefe.get_node("Modelo").rotation.y = atan2(-hacia.x, -hacia.z)
		_jefe.global_position = _jefe.global_position.move_toward(objetivo, 6.85 * delta)
		if _jefe.global_position.distance_squared_to(objetivo) < 0.009:
			_huellas.pop_front()

	if poblado.overlaps_body(jugador) and _jefe_llego():
		Encargos.contar(RESCATE.clave_de_conteo, &"regresar")
		Encargos.entregar(RESCATE)


func _jefe_llego() -> bool:
	var local := poblado.to_local(_jefe.global_position).abs()
	var mitad := _volumen.size * 0.5
	return local.x <= mitad.x and local.y <= mitad.y and local.z <= mitad.z
