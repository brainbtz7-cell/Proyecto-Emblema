class_name Seguimiento
extends PanelContainer
## Deja a la vista el siguiente paso. El diario muestra todos los encargos.
##
## Estilo minimalista: el nombre del lugar no vive acá (aparece en un cartel al
## entrar) y la indicación se ve unos segundos cada vez que cambia. Si no queda
## nada que mostrar, el panel se vuelve transparente.

## Ancho del seguimiento en la resolución de referencia de la interfaz.
@export_range(260.0, 420.0, 1.0) var ancho := 338.0
## Segundos que queda a la vista una indicación nueva. Con 0 no se oculta nunca.
@export_range(0.0, 60.0, 1.0) var segundos_de_indicacion := 14.0

const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")

var _primer_paso := ""
var _indicacion_vista := ""
var _tiempo_de_indicacion := 0.0
var _salida_de_indicacion: Tween

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
	_ubicacion.hide()
	_division.hide()
	_actualizar()


func _process(delta: float) -> void:
	if segundos_de_indicacion <= 0.0 or _tiempo_de_indicacion <= 0.0:
		return
	_tiempo_de_indicacion -= delta
	if _tiempo_de_indicacion <= 0.0:
		_salida_de_indicacion = create_tween()
		_salida_de_indicacion.tween_property(_indicacion, "modulate:a", 0.0, 0.5)
		_salida_de_indicacion.tween_callback(_ocultar_indicacion)


## El nombre se muestra en el cartel del lugar; acá solo importa el primer paso.
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
		if Encargos.estado_de(encargo) == Encargos.Estado.CUMPLIDO:
			elegido = encargo
			break
		# Las misiones de La Voz son de largo plazo: el encargo local va primero.
		if elegido == null or (elegido.de_la_voz and not encargo.de_la_voz):
			elegido = encargo
	_titulo.visible = elegido != null
	_objetivo.visible = elegido != null
	_otros.visible = abiertos.size() > 1
	_otros.text = "+%d en el diario" % (abiertos.size() - 1)
	theme_type_variation = &"PanelSeguimientoDeLaVoz" if elegido and elegido.de_la_voz else &"PanelSeguimiento"
	var indicacion := ""
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
		indicacion = "" if cumplido else elegido.indicacion_para(Encargos.avance_de(elegido))
	else:
		_objetivo.text = ""
		_progreso.hide()
		indicacion = _primer_paso
		if _primer_paso.is_empty() and Encargos.estado_de(LOMOS) == Encargos.Estado.DISPONIBLE:
			indicacion = "Hablá con el pescador para empezar."
	_mostrar_indicacion(indicacion)
	_ajustar_alto.call_deferred()


# Una indicación nueva se ve entera unos segundos; la misma no reinicia el tiempo.
func _mostrar_indicacion(texto: String) -> void:
	_indicacion.text = texto
	if texto == _indicacion_vista and not _indicacion.visible:
		_actualizar_presencia()
		return
	if texto != _indicacion_vista:
		_indicacion_vista = texto
		_tiempo_de_indicacion = segundos_de_indicacion
		if _salida_de_indicacion and _salida_de_indicacion.is_valid():
			_salida_de_indicacion.kill()
		_indicacion.modulate.a = 1.0
	_indicacion.visible = not texto.is_empty()
	_actualizar_presencia()


func _ocultar_indicacion() -> void:
	_indicacion.hide()
	_actualizar_presencia()
	_ajustar_alto.call_deferred()


# Sin título ni indicación no queda nada que leer: el panel se vuelve transparente.
func _actualizar_presencia() -> void:
	modulate.a = 1.0 if _titulo.visible or _indicacion.visible else 0.0


## El texto envuelto recalcula su mínimo después de distribuir la columna.
## No reiniciar el ancho: lo angosta y deja una altura antigua de muchas líneas.
func _ajustar_alto() -> void:
	size.y = get_combined_minimum_size().y
