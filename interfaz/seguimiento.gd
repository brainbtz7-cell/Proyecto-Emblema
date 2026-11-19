class_name Seguimiento
extends PanelContainer
## Deja a la vista el siguiente paso. El diario muestra todos los encargos.

## Ancho del seguimiento en la resolución de referencia de la interfaz.
@export_range(260.0, 420.0, 1.0) var ancho := 338.0

const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")

var _primer_paso := ""

@onready var _ubicacion: Label = $Columna/Ubicacion
@onready var _division: HSeparator = $Columna/Division
@onready var _titulo: Label = $Columna/Titulo
@onready var _objetivo: Label = $Columna/Objetivo
@onready var _progreso: ProgressBar = $Columna/Progreso
@onready var _indicacion: Label = $Columna/Indicacion
@onready var _otros: Label = $Columna/Otros


func _ready() -> void:
	custom_minimum_size.x = ancho
	size.x = ancho
	minimum_size_changed.connect(_ajustar_alto.call_deferred)
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
		_titulo.theme_type_variation = &"EnfasisDeLaVoz" if elegido.de_la_voz else &"Enfasis"
		_objetivo.text = "Volvé con %s" % elegido.entregar_a if cumplido else "%s   %d/%d" % [
			elegido.objetivo, Encargos.avance_de(elegido), elegido.cantidad
		]
		_objetivo.theme_type_variation = &"Confirmado" if cumplido else &"Label"
		_progreso.max_value = elegido.cantidad
		_progreso.value = Encargos.avance_de(elegido)
		_progreso.theme_type_variation = &"ProgresoDeLaVoz" if elegido.de_la_voz else &"ProgressBar"
		_progreso.visible = not cumplido
		_indicacion.text = "" if cumplido else elegido.indicacion
	else:
		_objetivo.text = ""
		_progreso.hide()
		_indicacion.text = _primer_paso
		if _primer_paso.is_empty() and Encargos.estado_de(LOMOS) == Encargos.Estado.DISPONIBLE:
			_indicacion.text = "Hablá con el pescador para empezar."
	_indicacion.visible = not _indicacion.text.is_empty()
	_division.visible = _titulo.visible or _indicacion.visible
	_ajustar_alto.call_deferred()


## El texto envuelto recalcula su mínimo después de distribuir la columna.
## No reiniciar el ancho: lo angosta y deja una altura antigua de muchas líneas.
func _ajustar_alto() -> void:
	size.y = get_combined_minimum_size().y
