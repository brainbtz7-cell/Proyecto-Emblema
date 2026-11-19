class_name Dialogo
extends Control
## Caja de diálogo: escribe el texto letra por letra y puede ofrecer opciones.
##
## Uso desde otro script:
##     await Interfaz.dialogo.decir("Pescador", "Hola.")
##     var eleccion: int = await Interfaz.dialogo.preguntar("Pescador", "¿Me ayudas?", ["Sí", "No"])
##     Interfaz.dialogo.cerrar()
##
## El texto se pasa con E, Espacio, Enter o un clic.

signal _texto_completo
signal _avanzado
signal _elegido(indice: int)

const NOMBRE_DE_LA_VOZ := "La Voz"

## Letras que se escriben por segundo.
@export var rapidez := 45.0

## Verdadero mientras la caja está en pantalla.
var abierto := false
## Momento, en milisegundos, en que se cerró por última vez.
var cerrado_en := -100000

var _escribiendo := false
var _letras := 0.0
var _salida := -1
var _raton_anterior := Input.MOUSE_MODE_VISIBLE

@onready var _caja: PanelContainer = $Caja
@onready var _nombre: Label = $Caja/Columna/Nombre
@onready var _texto: Label = $Caja/Columna/Texto
@onready var _opciones: HBoxContainer = $Caja/Columna/Opciones
@onready var _seguir: Button = $Caja/Columna/Seguir


func _ready() -> void:
	visible = false
	_seguir.pressed.connect(_seguir_dialogo)
	Interfaz.dispositivo_cambiado.connect(_actualizar_pie)
	_caja.minimum_size_changed.connect(Interfaz.ajustar_alto.bind(_caja).call_deferred)


## Muestra un texto y espera a que el jugador lo pase.
## Con "quien" vacío se muestra como aviso del juego, sin nombre.
func decir(quien: String, texto: String) -> void:
	_mostrar(quien, texto)
	await _avanzado


## Muestra un texto con opciones y devuelve el número de la elegida (0 es la primera).
func preguntar(quien: String, texto: String, opciones: PackedStringArray, salida := -1) -> int:
	_mostrar(quien, texto)
	_salida = salida
	await _texto_completo
	_seguir.visible = false
	_opciones.show()
	for i in opciones.size():
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(138, 41)
		boton.text = opciones[i]
		if i == 0:
			boton.theme_type_variation = &"BotonPrincipal"
		boton.pressed.connect(_elegido.emit.bind(i))
		_opciones.add_child(boton)
	(_opciones.get_child(0) as Button).grab_focus()
	var indice: int = await _elegido
	for boton in _opciones.get_children():
		_opciones.remove_child(boton)
		boton.queue_free()
	_opciones.hide()
	return indice


## Cierra la caja al terminar la conversación.
func cerrar() -> void:
	if not abierto:
		return
	abierto = false
	cerrado_en = Time.get_ticks_msec()
	Input.mouse_mode = _raton_anterior
	visible = false


func _process(delta: float) -> void:
	if not _escribiendo:
		return
	_letras += rapidez * delta
	_texto.visible_characters = int(_letras)
	if _letras >= _texto.text.length():
		_terminar_de_escribir()


func _input(evento: InputEvent) -> void:
	if not abierto or evento.is_echo():
		return
	if _opciones.visible:
		if evento.is_action_pressed(&"ui_cancel") and _salida >= 0:
			get_viewport().set_input_as_handled()
			_elegido.emit(_salida)
		elif evento.is_action_pressed(&"interactuar"):
			var enfocado := get_viewport().gui_get_focus_owner() as Button
			if enfocado and enfocado.get_parent() == _opciones:
				get_viewport().set_input_as_handled()
				enfocado.pressed.emit()
		return
	var clic := evento as InputEventMouseButton
	var avanza := evento.is_action_pressed(&"interactuar") or evento.is_action_pressed(&"ui_accept")
	if clic and clic.pressed and clic.button_index == MOUSE_BUTTON_LEFT:
		avanza = true
	if not avanza:
		return
	get_viewport().set_input_as_handled()
	_seguir_dialogo()


func _seguir_dialogo() -> void:
	if _escribiendo:
		# El primer toque completa el texto; el siguiente lo pasa.
		_terminar_de_escribir()
	elif _opciones.get_child_count() == 0:
		_avanzado.emit()


func _mostrar(quien: String, texto: String) -> void:
	if not abierto:
		abierto = true
		visible = true
		Interfaz.animar_entrada(self)
		# El ratón queda libre para poder elegir opciones con un clic.
		_raton_anterior = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_nombre.text = quien
	_nombre.visible = quien != ""
	var de_la_voz := quien == NOMBRE_DE_LA_VOZ
	_caja.theme_type_variation = &"PanelDialogoDeLaVoz" if de_la_voz else &"PanelContainer"
	_nombre.theme_type_variation = &"NombreDeLaVoz" if de_la_voz else &"Nombre"
	_texto.theme_type_variation = &"TextoDeLaVoz" if de_la_voz else &"Label"
	_salida = -1
	_texto.text = texto
	_texto.visible_characters = 0
	_letras = 0.0
	_escribiendo = true
	_opciones.hide()
	_seguir.show()
	_actualizar_pie()


func _terminar_de_escribir() -> void:
	_escribiendo = false
	_texto.visible_characters = -1
	_actualizar_pie()
	_texto_completo.emit()


func _actualizar_pie() -> void:
	var tecla: String = Interfaz.tecla(&"interactuar", Interfaz.con_mando)
	var accion := "Mostrar texto" if _escribiendo else "Continuar"
	_seguir.text = "%s   %s" % [tecla, accion]
