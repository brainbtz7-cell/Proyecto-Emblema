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

@onready var _zona: Interactuable = $Interactuable


func _ready() -> void:
	_zona.accion = accion
	_zona.usado.connect(_al_usar)
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func _actualizar() -> void:
	_zona.disponible = habilitado_por == null or Encargos.estado_de(habilitado_por) != Encargos.Estado.DISPONIBLE


func _al_usar(jugador: Jugador) -> void:
	if destino == null:
		return
	var velo := ColorRect.new()
	velo.color = Color(0.03, 0.05, 0.1, 0.0)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var capa := CanvasLayer.new()
	capa.layer = 20
	capa.add_child(velo)
	get_tree().root.add_child(capa)
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
	capa.queue_free()
