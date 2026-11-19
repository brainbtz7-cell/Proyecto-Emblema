class_name Recolectable
extends Node3D
## Objeto de misión que se junta con E. Solo aparece mientras un encargo
## activo lo pide, como los lomos de Uscita.

## Clave que suma al recogerlo (Encargos.contar).
@export var clave: StringName
@export var accion := "Recolectar"

@onready var _zona: Interactuable = $Interactuable


func _ready() -> void:
	_zona.accion = accion
	_zona.usado.connect(_al_recoger)
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func _actualizar() -> void:
	var visible_ahora := Encargos.hace_falta(clave) and not _ya_recogido()
	visible = visible_ahora
	_zona.disponible = visible_ahora


func _al_recoger(_jugador: Jugador) -> void:
	if _ya_recogido() or not Encargos.hace_falta(clave):
		return
	Encargos.contar(clave, StringName(get_path()))
	Sonido.efecto(&"paso_arena", 0.0)
	_actualizar()


func _ya_recogido() -> bool:
	for encargo in Encargos.en_curso():
		if encargo.clave_de_conteo == clave and Encargos.contado(encargo, StringName(get_path())):
			return true
	return false
