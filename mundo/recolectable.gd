class_name Recolectable
extends Node3D
## Objeto de misión que se junta con E. Solo aparece mientras un encargo
## activo lo pide, como los lomos de Uscita.

## Clave que suma al recogerlo (Encargos.contar).
@export var clave: StringName
@export var accion := "Recolectar"

var _recogido := false

@onready var _zona: Interactuable = $Interactuable


func _ready() -> void:
	_zona.accion = accion
	_zona.usado.connect(_al_recoger)
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func _actualizar() -> void:
	var visible_ahora := not _recogido and Encargos.hace_falta(clave)
	visible = visible_ahora
	_zona.disponible = visible_ahora


func _al_recoger(_jugador: Jugador) -> void:
	if _recogido or not Encargos.hace_falta(clave):
		return
	_recogido = true
	Encargos.contar(clave)
	Sonido.efecto(&"paso_arena", 0.0)
	_actualizar()
