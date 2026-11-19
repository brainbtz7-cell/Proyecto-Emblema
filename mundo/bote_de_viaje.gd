class_name BoteDeViaje
extends Node3D
## Bote que lleva al protagonista a otro muelle (por ejemplo, de Albor al
## Cayo de Salcristal). La travesía es un fundido: no se maneja el bote.

## Lugar donde aparece el protagonista al llegar.
@export var destino: Node3D
@export var accion := "Viajar en bote"
## Si tiene un encargo, el bote solo se puede usar con ese encargo aceptado
## (o ya entregado).
@export var habilitado_por: Encargo

var _viajando := false
var _capa: CanvasLayer

@onready var _zona: Interactuable = $Interactuable


func _ready() -> void:
	_zona.accion = accion
	_zona.usado.connect(_al_usar)
	Encargos.cambiado.connect(_actualizar)
	tree_exiting.connect(_limpiar_travesia)
	_actualizar()


func _actualizar() -> void:
	_zona.disponible = not _viajando and (habilitado_por == null or Encargos.estado_de(habilitado_por) != Encargos.Estado.DISPONIBLE)


func _al_usar(jugador: Jugador) -> void:
	if destino == null or not _zona.disponible or Interfaz.ocupada():
		return
	_viajando = true
	Interfaz.en_travesia = true
	jugador.velocity = Vector3.ZERO
	_actualizar()
	var velo := ColorRect.new()
	velo.color = Color(0.03, 0.05, 0.1, 0.0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_capa = CanvasLayer.new()
	_capa.layer = 20
	_capa.add_child(velo)
	get_tree().root.add_child(_capa)
	var tiempo := create_tween()
	tiempo.tween_property(velo, "color:a", 1.0, 0.45)
	await tiempo.finished
	Sonido.efecto(&"paso_agua", 0.0)
	jugador.teletransportar(destino.global_position)
	jugador.modelo.global_rotation.y = destino.global_rotation.y
	await get_tree().create_timer(0.35).timeout
	tiempo = create_tween()
	tiempo.tween_property(velo, "color:a", 0.0, 0.45)
	await tiempo.finished
	_limpiar_travesia()
	_actualizar()
	Interfaz.registrar_cierre()


func _limpiar_travesia() -> void:
	if not _viajando:
		return
	_viajando = false
	if is_instance_valid(_capa):
		_capa.queue_free()
	if is_instance_valid(Interfaz):
		Interfaz.en_travesia = false
