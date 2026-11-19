class_name MenuDePausa
extends Control

signal volver
signal reiniciar

const DIARIO := 0
const CONTROLES := 1
const PARTIDA := 2

var pagina := PARTIDA

@onready var _diario: VBoxContainer = $Caja/Columna/Cuerpo/Interior/Paginas/Diario
@onready var _lista: VBoxContainer = $Caja/Columna/Cuerpo/Interior/Paginas/Diario/Lista
@onready var _controles: VBoxContainer = $Caja/Columna/Cuerpo/Interior/Paginas/Controles
@onready var _tabla: GridContainer = $Caja/Columna/Cuerpo/Interior/Paginas/Controles/Tabla
@onready var _imagen: HBoxContainer = $Caja/Columna/Cuerpo/Interior/Paginas/Controles/Imagen
@onready var _resolucion: Label = _imagen.get_node("Resolucion")
@onready var _grueso: Button = _imagen.get_node("Grueso")
@onready var _fino: Button = _imagen.get_node("Fino")
@onready var _interior: ScrollContainer = $Caja/Columna/Cuerpo/Interior
@onready var _boton_diario: Button = $Caja/Columna/Cuerpo/Menu/Diario
@onready var _boton_controles: Button = $Caja/Columna/Cuerpo/Menu/Controles
@onready var _desplazar: Label = $Caja/Columna/Pie/Desplazar
@onready var _partida: VBoxContainer = $Caja/Columna/Cuerpo/Interior/Paginas/Partida
@onready var _boton_partida: Button = $Caja/Columna/Cuerpo/Menu/Partida
@onready var _guardar: Button = _partida.get_node("Acciones/Guardar")
@onready var _borrar: Button = _partida.get_node("Acciones/Borrar")
@onready var _estado_partida: Label = _partida.get_node("Estado")
@onready var _confirmacion: VBoxContainer = _partida.get_node("Confirmacion")
@onready var _cancelar: Button = _confirmacion.get_node("Botones/Cancelar")
@onready var _confirmar: Button = _confirmacion.get_node("Botones/Confirmar")
@onready var _cerrar: Label = $Caja/Columna/Pie/Cerrar


func _ready() -> void:
	$Caja/Columna/Cabecera/Volver.pressed.connect(volver.emit)
	_boton_diario.pressed.connect(mostrar_pagina.bind(DIARIO))
	_boton_controles.pressed.connect(mostrar_pagina.bind(CONTROLES))
	_grueso.pressed.connect(Pixelado.cambiar_alto.bind(-1))
	_fino.pressed.connect(Pixelado.cambiar_alto.bind(1))
	Pixelado.cambiado.connect(_actualizar_resolucion)
	Encargos.cambiado.connect(_actualizar_diario)
	_boton_partida.pressed.connect(mostrar_pagina.bind(PARTIDA))
	_guardar.icon = preload("res://interfaz/iconos/guardar.svg")
	_guardar.pressed.connect(_guardar_partida)
	_borrar.pressed.connect(_pedir_borrado)
	_cancelar.pressed.connect(cancelar_borrado)
	_confirmar.pressed.connect(_borrar_partida)
	Guardado.cambiado.connect(_actualizar_partida)
	_actualizar_resolucion()


func mostrar_pagina(destino: int) -> void:
	cancelar_borrado()
	pagina = destino
	_diario.visible = pagina == DIARIO
	_controles.visible = pagina == CONTROLES
	_partida.visible = pagina == PARTIDA
	_boton_partida.set_pressed_no_signal(pagina == PARTIDA)
	_boton_diario.set_pressed_no_signal(pagina == DIARIO)
	_boton_controles.set_pressed_no_signal(pagina == CONTROLES)
	if pagina == DIARIO:
		_actualizar_diario()
	elif pagina == CONTROLES:
		_actualizar_controles()
	else:
		_actualizar_partida()
	_interior.scroll_vertical = 0
	var botones: Array[Button] = [_boton_diario, _boton_controles, _boton_partida]
	botones[pagina].grab_focus()
	actualizar_atajos()


func actualizar_atajos() -> void:
	if not visible:
		return
	_cerrar.text = "%s  Volver" % Interfaz.tecla(&"pausar", Interfaz.con_mando)
	_desplazar.text = "Palanca derecha para desplazar" if Interfaz.con_mando else "Rueda o Re Pág / Av Pág para desplazar"


func _process(delta: float) -> void:
	if visible and Interfaz.con_mando:
		var eje := Input.get_axis(&"camara_arriba", &"camara_abajo")
		_interior.scroll_vertical += roundi(eje * delta * 470.0)


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed(&"ui_page_down"):
		_interior.scroll_vertical += roundi(_interior.size.y * 0.85)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed(&"ui_page_up"):
		_interior.scroll_vertical -= roundi(_interior.size.y * 0.85)
		get_viewport().set_input_as_handled()


func _actualizar_diario() -> void:
	if not visible or pagina != DIARIO:
		return
	var desplazamiento := _interior.scroll_vertical
	_vaciar(_lista)
	var historial := Encargos.historial()
	if historial.is_empty():
		_lista.add_child(_rotulo("Todavía no aceptaste encargos. Hablá con el pescador para empezar.", &"Secundario"))
		return
	var en_curso := Encargos.en_curso()
	if not en_curso.is_empty():
		_lista.add_child(_rotulo("En curso · %d" % en_curso.size(), &"Etiqueta"))
	for encargo in en_curso:
		_agregar_encargo(encargo)
	var entregados := historial.size() - en_curso.size()
	if entregados > 0:
		_lista.add_child(_rotulo("Entregados · %d" % entregados, &"Etiqueta"))
	for encargo in historial:
		if Encargos.estado_de(encargo) == Encargos.Estado.COMPLETADO:
			_agregar_encargo(encargo)
	_interior.set_deferred("scroll_vertical", desplazamiento)


func _agregar_encargo(encargo: Encargo) -> void:
	var ficha := PanelContainer.new()
	ficha.theme_type_variation = &"PanelBitacora"
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override(&"separation", 5)
	var estado := Encargos.estado_de(encargo)
	var nombre := _rotulo(encargo.titulo, &"Enfasis")
	var resumen := _rotulo("", &"Secundario")
	var nota := ""
	match estado:
		Encargos.Estado.ACTIVO:
			resumen.text = "%s  ·  %d/%d" % [encargo.objetivo, Encargos.avance_de(encargo), encargo.cantidad]
			nota = encargo.indicacion
		Encargos.Estado.CUMPLIDO:
			resumen.text = "Listo para entregar  ·  Volvé con %s" % encargo.entregar_a
			resumen.theme_type_variation = &"Confirmado"
		Encargos.Estado.COMPLETADO:
			resumen.text = "Entregado"
			resumen.theme_type_variation = &"Confirmado"
			nota = encargo.cierre
	columna.add_child(nombre)
	columna.add_child(resumen)
	if estado == Encargos.Estado.ACTIVO:
		var progreso := ProgressBar.new()
		progreso.custom_minimum_size.y = 5.0
		progreso.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progreso.show_percentage = false
		progreso.max_value = encargo.cantidad
		progreso.value = Encargos.avance_de(encargo)
		columna.add_child(progreso)
	if not nota.is_empty():
		columna.add_child(_rotulo(nota, &"Secundario"))
	ficha.add_child(columna)
	_lista.add_child(ficha)


func _actualizar_controles() -> void:
	_vaciar(_tabla)
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


func _vaciar(contenedor: Container) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


func _guardar_partida() -> void:
	Guardado.guardar()
	_actualizar_partida()


func _actualizar_partida() -> void:
	_estado_partida.text = Guardado.ultimo_mensaje
	if not Guardado.fecha.is_empty():
		_estado_partida.text += "\nÚltimo guardado: " + Guardado.fecha
	_borrar.disabled = not Guardado.hay_partida()


func _pedir_borrado() -> void:
	_confirmacion.show()
	_guardar.disabled = true
	_borrar.disabled = true
	_cancelar.grab_focus()


## Esc primero cancela el borrado; otro toque vuelve al juego.
func cancelar_borrado() -> bool:
	if not is_node_ready() or not _confirmacion.visible:
		return false
	_confirmacion.hide()
	_guardar.disabled = false
	_actualizar_partida()
	_borrar.grab_focus()
	return true


func _borrar_partida() -> void:
	if Guardado.borrar():
		cancelar_borrado()
		reiniciar.emit()
	else:
		cancelar_borrado()
