class_name Seguimiento
extends PanelContainer
## Deja a la vista el siguiente paso. El diario muestra todos los encargos.

const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")

var _primer_paso := "Hablá con el pescador para empezar."

@onready var _ubicacion: Label = $Columna/Ubicacion
@onready var _division: HSeparator = $Columna/Division
@onready var _titulo: Label = $Columna/Titulo
@onready var _objetivo: Label = $Columna/Objetivo
@onready var _progreso: ProgressBar = $Columna/Progreso
@onready var _indicacion: Label = $Columna/Indicacion
@onready var _otros: Label = $Columna/Otros


func _ready() -> void:
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func establecer_ubicacion(nombre: String, primer_paso: String) -> void:
	if _ubicacion.text == nombre and _primer_paso == primer_paso:
		return
	_ubicacion.text = nombre
	_primer_paso = primer_paso
	_actualizar()


func _actualizar() -> void:
	var abiertos := Encargos.en_curso()
	var elegido: Encargo
	for encargo in abiertos:
		if elegido == null:
			elegido = encargo
		if Encargos.estado_de(encargo) == Encargos.Estado.CUMPLIDO:
			elegido = encargo
			break
	_titulo.visible = elegido != null
	_objetivo.visible = elegido != null
	_otros.visible = abiertos.size() > 1
	_otros.text = "%d más en el diario" % (abiertos.size() - 1)
	if elegido:
		var cumplido := Encargos.estado_de(elegido) == Encargos.Estado.CUMPLIDO
		_titulo.text = elegido.titulo
		_objetivo.text = "Volvé con %s" % elegido.entregar_a if cumplido else "%s   %d/%d" % [
			elegido.objetivo, Encargos.avance_de(elegido), elegido.cantidad
		]
		_objetivo.theme_type_variation = &"Confirmado" if cumplido else &"Label"
		_progreso.max_value = elegido.cantidad
		_progreso.value = Encargos.avance_de(elegido)
		_progreso.visible = not cumplido
		_indicacion.text = "" if cumplido else elegido.indicacion
	else:
		_objetivo.text = ""
		_progreso.hide()
		_indicacion.text = _primer_paso if Encargos.estado_de(LOMOS) == Encargos.Estado.DISPONIBLE else ""
	_indicacion.visible = not _indicacion.text.is_empty()
	_division.visible = _titulo.visible or _indicacion.visible
	reset_size()
