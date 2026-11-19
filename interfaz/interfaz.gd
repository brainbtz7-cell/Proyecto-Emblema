extends CanvasLayer
## Mantiene un solo panel activo y actualiza los atajos según el dispositivo.

signal solicitar_mapa
signal dispositivo_cambiado

## Duración de la entrada de menús, diálogos y mapa, en segundos.
@export_range(0.0, 0.4, 0.01) var duracion_de_entrada := 0.16
## Segundos que se mantiene cada aviso de encargo durante la exploración.
@export_range(2.0, 6.0, 0.1) var duracion_del_aviso := 3.5

const MARGEN_TRAS_CIERRE := 200
const MARGEN_DEL_GUARDADO := 24.0
const BOTONES_MANDO := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Vista", JOY_BUTTON_START: "Menú", JOY_BUTTON_LEFT_STICK: "L3",
}
const NOMBRES_TECLAS := {KEY_ESCAPE: "Esc", KEY_SPACE: "Espacio", KEY_ENTER: "Enter"}

var con_mando := false
var mapa_abierto := false:
	set(valor):
		mapa_abierto = valor
		_actualizar_hud()

var _ultimo_cierre := -100000
var _raton_anterior := Input.MOUSE_MODE_VISIBLE
var _pausado_antes := false
var _en_menu_principal := false
var _avisos_pendientes: Dictionary[Encargo, int] = {}
var _tiempo_del_aviso := 0.0
var _explorando := true
var _tiempo_de_guardado := 0.0
var _error_de_guardado := false

@onready var dialogo: Dialogo = $Dialogo
@onready var combate: CombateDePrueba = $Combate
@onready var _pausa: MenuDePausa = $Pausa
@onready var _aviso: CenterContainer = $Aviso
@onready var _accion: Label = $Aviso/Caja/Fila/Accion
@onready var _tecla_del_aviso: Label = $Aviso/Caja/Fila/Tecla/Texto
@onready var _atajos: HBoxContainer = $Atajos
@onready var _mapa: Button = $Atajos/Mapa
@onready var _diario: Button = $Atajos/Diario
@onready var _boton_pausa: Button = $Atajos/Pausa
@onready var _seguimiento: Seguimiento = $Seguimiento
@onready var _notificacion: PanelContainer = $Notificacion
@onready var _estado_del_aviso: Label = $Notificacion/Columna/Estado
@onready var _titulo_del_aviso: Label = $Notificacion/Columna/Titulo
@onready var _estado_guardado: PanelContainer = $EstadoGuardado
@onready var _texto_guardado: Label = $EstadoGuardado/Texto


func _ready() -> void:
	dialogo.visibility_changed.connect(_actualizar_hud)
	combate.visibility_changed.connect(_actualizar_hud)
	_mapa.pressed.connect(_pedir_mapa)
	_diario.pressed.connect(_abrir_pausa.bind(MenuDePausa.DIARIO))
	_boton_pausa.pressed.connect(_abrir_pausa.bind(MenuDePausa.PARTIDA))
	_pausa.volver.connect(_cerrar_pausa)
	_pausa.reiniciar.connect(_reiniciar_partida)
	Encargos.hito.connect(_anotar_hito)
	Guardado.resultado.connect(_mostrar_resultado_guardado)
	_estado_guardado.minimum_size_changed.connect(ajustar_alto.bind(_estado_guardado, MARGEN_DEL_GUARDADO).call_deferred)
	_notificacion.minimum_size_changed.connect(ajustar_alto.bind(_notificacion).call_deferred)
	for boton: Button in [_mapa, _diario, _boton_pausa]:
		boton.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mapa.icon = preload("res://interfaz/iconos/mapa.svg")
	_diario.icon = preload("res://interfaz/iconos/diario.svg")
	_boton_pausa.icon = preload("res://interfaz/iconos/pausa.svg")
	_actualizar_atajos()
	_actualizar_hud()


func _input(evento: InputEvent) -> void:
	_detectar_dispositivo(evento)
	if _en_menu_principal or evento.is_echo():
		return
	var diario := evento.is_action_pressed(&"ver_diario")
	var pausa := evento.is_action_pressed(&"pausar")
	if _pausa.visible:
		if pausa or evento.is_action_pressed(&"ui_cancel") or (diario and _pausa.pagina == MenuDePausa.DIARIO):
			if not _pausa.cancelar_borrado():
				_cerrar_pausa()
		elif diario:
			_pausa.mostrar_pagina(MenuDePausa.DIARIO)
		else:
			return
		get_viewport().set_input_as_handled()
	elif (pausa or diario) and not ocupada():
		if pausa and evento.is_action_pressed(&"soltar_raton") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			_abrir_pausa(MenuDePausa.DIARIO if diario else MenuDePausa.PARTIDA)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _explorando:
		return
	if not _error_de_guardado:
		_tiempo_de_guardado = maxf(0.0, _tiempo_de_guardado - delta)
	_estado_guardado.visible = _error_de_guardado or _tiempo_de_guardado > 0.0
	_estado_guardado.modulate.a = 1.0 if _error_de_guardado else minf(_tiempo_de_guardado * 3.0, 1.0)
	_tiempo_del_aviso = maxf(0.0, _tiempo_del_aviso - delta)
	if _tiempo_del_aviso <= 0.0 and not _avisos_pendientes.is_empty():
		var encargo: Encargo = _avisos_pendientes.keys()[0]
		var estado: int = _avisos_pendientes[encargo]
		_avisos_pendientes.erase(encargo)
		_titulo_del_aviso.text = encargo.titulo
		_titulo_del_aviso.theme_type_variation = &"EnfasisDeLaVoz" if encargo.de_la_voz else &"Enfasis"
		match estado:
			Encargos.Estado.ACTIVO:
				_estado_del_aviso.text = "Encargo aceptado"
			Encargos.Estado.CUMPLIDO:
				_estado_del_aviso.text = "Objetivo cumplido"
			Encargos.Estado.COMPLETADO:
				_estado_del_aviso.text = "Encargo entregado"
		_tiempo_del_aviso = duracion_del_aviso
		ajustar_alto.call_deferred(_notificacion)
	_notificacion.visible = _tiempo_del_aviso > 0.0
	_notificacion.modulate.a = clampf(minf((duracion_del_aviso - _tiempo_del_aviso) * 6.0, _tiempo_del_aviso * 3.0), 0.0, 1.0)


## Evita reutilizar la misma pulsación al volver a explorar.
func ocupada() -> bool:
	var ultimo_cierre := maxi(_ultimo_cierre, maxi(dialogo.cerrado_en, combate.cerrado_en))
	return _en_menu_principal or mapa_abierto or _pausa.visible or dialogo.abierto or combate.visible or Time.get_ticks_msec() - ultimo_cierre < MARGEN_TRAS_CIERRE


## Suspende los atajos y el HUD hasta que el menú abra el mundo.
func establecer_en_menu_principal(activo: bool) -> void:
	_en_menu_principal = activo
	_actualizar_hud()


func establecer_mapa_disponible(disponible: bool) -> void:
	_mapa.visible = disponible
	if not disponible:
		establecer_ubicacion("Isla de pruebas", "")


func establecer_ubicacion(nombre: String, primer_paso: String) -> void:
	_seguimiento.establecer_ubicacion(nombre, primer_paso)


func mostrar_aviso(accion: String) -> void:
	if _accion.text == accion:
		return
	_accion.text = accion
	_aviso.visible = _explorando and not accion.is_empty()


## Etiqueta de la tecla o el botón configurado para una acción.
func tecla(accion: StringName, mando: bool) -> String:
	for evento in InputMap.action_get_events(accion):
		if mando and evento is InputEventJoypadButton:
			return BOTONES_MANDO.get(evento.button_index, "Botón %d" % evento.button_index)
		if not mando and evento is InputEventKey:
			var codigo: Key = evento.physical_keycode if evento.physical_keycode else evento.keycode
			return NOMBRES_TECLAS.get(codigo, OS.get_keycode_string(codigo))
	return "—"


func registrar_cierre() -> void:
	_ultimo_cierre = Time.get_ticks_msec()
	mostrar_aviso("")


func _pedir_mapa() -> void:
	if not ocupada():
		solicitar_mapa.emit()


func _abrir_pausa(pagina: int) -> void:
	if ocupada():
		return
	_raton_anterior = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pausado_antes = get_tree().paused
	get_tree().paused = true
	_pausa.show()
	animar_entrada(_pausa)
	_pausa.mostrar_pagina(pagina)
	_actualizar_hud()


func _cerrar_pausa() -> void:
	_pausa.hide()
	get_tree().paused = _pausado_antes
	Input.mouse_mode = _raton_anterior
	registrar_cierre()
	_actualizar_hud()


func _anotar_hito(encargo: Encargo, estado: int) -> void:
	_avisos_pendientes[encargo] = estado


func _actualizar_hud() -> void:
	_explorando = not (_en_menu_principal or mapa_abierto or _pausa.visible or dialogo.visible or combate.visible)
	_atajos.visible = _explorando
	_seguimiento.visible = _explorando
	_aviso.visible = _explorando and not _accion.text.is_empty()
	_notificacion.visible = _explorando and _tiempo_del_aviso > 0.0
	_estado_guardado.visible = _explorando and (_error_de_guardado or _tiempo_de_guardado > 0.0)


func _actualizar_atajos() -> void:
	_mapa.text = "%s   Mapa" % tecla(&"ver_mapa", con_mando)
	_diario.text = "%s   Diario" % tecla(&"ver_diario", con_mando)
	_boton_pausa.text = "%s   Pausa" % tecla(&"pausar", con_mando)
	_tecla_del_aviso.text = tecla(&"interactuar", con_mando)


func _detectar_dispositivo(evento: InputEvent) -> void:
	var mando := con_mando
	if evento is InputEventJoypadButton and evento.pressed:
		mando = true
	elif evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.52:
		mando = true
	elif evento is InputEventKey and evento.pressed or evento is InputEventMouseButton and evento.pressed:
		mando = false
	if con_mando != mando:
		con_mando = mando
		_actualizar_atajos()
		_pausa.actualizar_atajos()
		dispositivo_cambiado.emit()


func _reiniciar_partida() -> void:
	_cerrar_pausa()
	_avisos_pendientes.clear()
	_tiempo_del_aviso = 0.0
	# El autoload conserva la interfaz y la escena repone los valores iniciales.
	get_tree().reload_current_scene()


## Transición breve que no retrasa las entradas ni cambia el tamaño del panel.
func animar_entrada(panel: CanvasItem) -> void:
	var anterior: Tween
	if panel.has_meta(&"entrada_de_interfaz"):
		anterior = panel.get_meta(&"entrada_de_interfaz")
	if anterior and anterior.is_valid():
		anterior.kill()
	panel.modulate.a = 0.0
	var entrada := panel.create_tween()
	panel.set_meta(&"entrada_de_interfaz", entrada)
	entrada.tween_property(panel, "modulate:a", 1.0, duracion_de_entrada).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Mantiene el ancho. En cajas ancladas abajo, vuelve a fijar el borde inferior.
func ajustar_alto(panel: Control, margen_inferior := -1.0) -> void:
	var alto := panel.get_combined_minimum_size().y
	if margen_inferior >= 0.0:
		panel.offset_bottom = -margen_inferior
		panel.offset_top = -margen_inferior - alto
	else:
		panel.size.y = alto


func _mostrar_resultado_guardado(correcto: bool, mensaje: String) -> void:
	_error_de_guardado = not correcto
	_tiempo_de_guardado = 3.0
	_texto_guardado.text = ("✓  " if correcto else "!  ") + mensaje
	_texto_guardado.theme_type_variation = &"Confirmado" if correcto else &"Advertencia"
	_estado_guardado.visible = _explorando
	ajustar_alto.call_deferred(_estado_guardado, MARGEN_DEL_GUARDADO)
