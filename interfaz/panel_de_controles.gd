class_name PanelDeControles
extends VBoxContainer

@onready var _tabla: GridContainer = $Tabla
@onready var _resolucion: Label = $Imagen/Resolucion
@onready var _grueso: Button = $Imagen/Grueso
@onready var _fino: Button = $Imagen/Fino


func _ready() -> void:
	_grueso.pressed.connect(Pixelado.cambiar_alto.bind(-1))
	_fino.pressed.connect(Pixelado.cambiar_alto.bind(1))
	Pixelado.cambiado.connect(_actualizar_resolucion)
	_actualizar_resolucion()
	# La interfaz global termina de entrar al árbol después de este panel.
	_cargar_acciones.call_deferred()


func _cargar_acciones() -> void:
	for titulo in ["Acción", "Teclado y ratón", "Mando"]:
		var cabecera := _rotulo(titulo, &"Etiqueta")
		cabecera.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_tabla.add_child(cabecera)
	_fila("Moverse", "WASD / flechas", "Palanca izq.")
	_fila("Correr", Interfaz.tecla(&"correr", false), Interfaz.tecla(&"correr", true))
	_fila("Saltar", Interfaz.tecla(&"saltar", false), Interfaz.tecla(&"saltar", true))
	_fila("Interactuar / avanzar", Interfaz.tecla(&"interactuar", false), Interfaz.tecla(&"interactuar", true))
	_fila("Girar / acercar cámara", "Clic y mover / Rueda", "Palanca der.")
	_fila("Abrir mapa / diario", "%s / %s" % [Interfaz.tecla(&"ver_mapa", false), Interfaz.tecla(&"ver_diario", false)],
		"%s / %s" % [Interfaz.tecla(&"ver_mapa", true), Interfaz.tecla(&"ver_diario", true)])
	_fila("Elegir en combate", "1–4 / Flechas y Enter", "Cruceta y A")
	_fila("Pausar / volver", Interfaz.tecla(&"pausar", false), Interfaz.tecla(&"pausar", true))
	_fila("Píxel mayor / menor", "%s / %s" % [Interfaz.tecla(&"pixel_mas_grande", false), Interfaz.tecla(&"pixel_mas_chico", false)], "—")


func _fila(accion: String, teclado: String, mando: String) -> void:
	_tabla.add_child(_rotulo(accion, &"Enfasis"))
	_tabla.add_child(_rotulo(teclado, &"Secundario"))
	_tabla.add_child(_rotulo(mando, &"Secundario"))


func _actualizar_resolucion() -> void:
	var resolucion := Pixelado.resolucion_interna
	_resolucion.text = "Imagen 3D  ·  %d × %d" % [resolucion.x, resolucion.y]
	_grueso.disabled = Pixelado.alto_interno == Pixelado.ALTOS_INTERNOS.front()
	_fino.disabled = Pixelado.alto_interno == Pixelado.ALTOS_INTERNOS.back()


func _rotulo(texto: String, estilo: StringName) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = estilo
	rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return rotulo
