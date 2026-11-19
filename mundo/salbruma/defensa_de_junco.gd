class_name DefensaDeJunco
extends Node3D
## Cada acopio aporta una vez. El encargo conserva cuáles se levantaron.

const ENCARGO := preload("res://encargos/puerto_junco_jefe_defensas.tres")
const POLVO := preload("res://efectos/polvo.tscn")

@export var clave: StringName
@export var sitio := ""

var _lista := false

@onready var _zona: Interactuable = $Interactuable
@onready var _senal: Label3D = $Senal
@onready var _materiales: Node3D = $Materiales
@onready var _barrera: Node3D = $Barrera
@onready var _forma: CollisionShape3D = $Cuerpo/Forma
@onready var _espacio: Area3D = $Espacio


func _ready() -> void:
	add_to_group(&"defensas_de_junco")
	_senal.text = "◇  " + sitio
	_zona.disponible = false
	_zona.usado.connect(_levantar)
	_espacio.body_exited.connect(_al_salir)

	await get_tree().physics_frame
	await get_tree().physics_frame
	var altura := Suelo.altura_en(self, global_position.x, global_position.z)
	if not is_nan(altura):
		global_position.y = altura

	Encargos.cambiado.connect(_actualizar)
	_actualizar(false)


func pendiente() -> bool:
	return _zona.disponible


func _levantar(_jugador: Jugador) -> void:
	if pendiente():
		Encargos.contar(ENCARGO.clave_de_conteo, clave)


func _actualizar(animar := true) -> void:
	var hecha := Encargos.contado(ENCARGO, clave)
	_zona.disponible = clave != &"" and not hecha and Encargos.estado_de(ENCARGO) == Encargos.Estado.ACTIVO
	_senal.visible = pendiente()
	if not hecha or _barrera.visible:
		return

	_materiales.hide()
	_barrera.show()
	if animar:
		_barrera.position.y = -1.25
		var efecto := POLVO.instantiate() as Node3D
		add_child(efecto)
		var montaje := create_tween()
		montaje.tween_property(_barrera, "position:y", 0.0, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await montaje.finished
	_lista = true
	_actualizar_colision()


func _al_salir(_cuerpo: Node3D) -> void:
	_actualizar_colision()


func _actualizar_colision() -> void:
	var ocupada := _espacio.has_overlapping_bodies()
	_forma.set_deferred(&"disabled", not _lista or ocupada)
