extends SceneTree
## Verifica el alto del HUD después de redistribuir textos y de abrir paneles.
## godot --headless --path . -s herramientas/prueba_interfaz.gd
## Con ventana, pasar -- <carpeta_de_salida> para guardar las pantallas en PNG.

const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")
const GUARDIA := preload("res://encargos/puerto_junco_guardia_asaltantes.tres")
const IMPOSTOR := preload("res://encargos/la_voz_desenmascara_al_impostor.tres")
const MENU := "res://interfaz/menu_principal.tscn"
const SALBRUMA := "res://mundo/salbruma/salbruma.tscn"

var _fallos := 0
var _carpeta_de_capturas := ""
var _encargos: Node
var _interfaz: Node
var _seguimiento: Control


func _initialize() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if not argumentos.is_empty():
		if DisplayServer.get_name() == "headless":
			print("Sin ventana: se ejecuta la prueba sin capturas.")
		else:
			_carpeta_de_capturas = argumentos[0]
			var error := DirAccess.make_dir_recursive_absolute(_carpeta_de_capturas)
			_verificar(error == OK, "Crear carpeta para las capturas")
			root.mode = Window.MODE_WINDOWED
			# Arriba de todo para que macOS no deje de dibujarla, sin tomar foco ni ratón.
			root.always_on_top = true
			root.unfocusable = true
			root.mouse_passthrough = true
	root.size = Vector2i(1280, 720)
	_encargos = root.get_node("Encargos")
	_interfaz = root.get_node("Interfaz")
	_seguimiento = _interfaz.get_node("Seguimiento")
	await _esperar()
	_comprobar_panel("Sin encargos")
	_encargos.aceptar(LOMOS)
	await _esperar()
	_comprobar_panel("Encargo activo")
	_encargos.aceptar(GUARDIA)
	await _esperar()
	_comprobar_panel("Dos encargos activos")
	_verificar(_seguimiento.get_node("Columna/Otros").visible, "El HUD deriva los demás encargos al diario")
	for i in LOMOS.cantidad:
		_encargos.contar(LOMOS.clave_de_conteo)
	await _esperar()
	_comprobar_panel("Objetivo cumplido")
	_verificar(not _seguimiento.get_node("Columna/Progreso").visible, "Un encargo cumplido muestra la entrega sin barra")
	_encargos.entregar(LOMOS)
	await _esperar()
	_comprobar_panel("Encargo entregado")
	_interfaz.establecer_ubicacion("Caleta de las Redes Rotas", "Seguí el sendero hasta Puerto Junco.")
	await _esperar()
	_comprobar_panel("Nombre largo de ubicación")
	_encargos.desde_diccionario({})
	await _esperar()
	_comprobar_panel("Reinicio de partida")
	# Las resoluciones usan el mismo lienzo de referencia de Godot.
	for resolucion in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		root.size = resolucion
		await _esperar()
		_comprobar_panel("Ventana %s" % resolucion)
	await _probar_paneles()
	await _probar_menu_principal()
	print("INTERFAZ: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(0 if _fallos == 0 else 1)


func _comprobar_panel(caso: String) -> void:
	var minimo := _seguimiento.get_combined_minimum_size()
	_verificar(absf(_seguimiento.size.y - minimo.y) < 1.0 and _seguimiento.size.y < 330.0,
		"%s: alto ajustado %.0f px (mínimo %.0f)" % [caso, _seguimiento.size.y, minimo.y])
	_verificar(absf(_seguimiento.size.x - 338.0) < 1.0, "%s: ancho estable" % caso)


func _esperar() -> void:
	for i in 12:
		await process_frame


func _verificar(condicion: bool, descripcion: String) -> void:
	print("OK: " if condicion else "FALLO: ", descripcion)
	if not condicion:
		_fallos += 1


func _probar_paneles() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file(SALBRUMA)
	await scene_changed
	var escena := current_scene
	await _esperar()
	var guardado := root.get_node("Guardado")
	var carpeta := "/tmp/emblema_interfaz_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(carpeta)
	guardado.ruta = carpeta.path_join("partida.json")
	await _capturar("exploracion")
	# Abrir Partida por el mismo botón del HUD.
	_interfaz.get_node("Atajos/Pausa").pressed.emit()
	await _esperar()
	var pausa := _interfaz.get_node("Pausa") as Control
	var caja := pausa.get_node("Caja") as Control
	_verificar(pausa.visible and paused, "La pausa detiene el mundo")
	_verificar(not _seguimiento.visible, "La pausa oculta el HUD")
	_verificar(caja.size.y <= 600.0 and caja.size.x <= 1000.0, "El menú cabe en la pantalla de referencia")
	var partida := pausa.get_node("Caja/Columna/Cuerpo/Interior/Paginas/Partida") as Control
	_verificar(partida.visible, "La pausa abre la página Partida")
	await _capturar("pausa_partida")
	partida.get_node("Acciones/Guardar").pressed.emit()
	await _esperar()
	_verificar(guardado.hay_partida(), "Guardar desde el botón del menú")
	partida.get_node("Acciones/Borrar").pressed.emit()
	await _esperar()
	var confirmacion := partida.get_node("Confirmacion") as Control
	_verificar(confirmacion.visible, "El borrado requiere confirmar en el juego")
	_verificar(root.gui_get_focus_owner() == confirmacion.get_node("Botones/Cancelar"), "Conservar partida recibe el foco inicial")
	await _capturar("pausa_confirmacion")
	await _accion(&"pausar")
	_verificar(not confirmacion.visible and pausa.visible and guardado.hay_partida(), "Esc cancela el borrado sin cerrar la pausa")
	await _accion(&"pausar")
	_verificar(not pausa.visible and not paused and _seguimiento.visible, "Otro Esc vuelve a explorar")
	var estado_guardado := _interfaz.get_node("EstadoGuardado") as Control
	_comprobar_pantalla(estado_guardado, "Aviso de guardado")
	_interfaz.mostrar_aviso("Hablar con el pescador")
	await _capturar("avisos_de_exploracion")
	_interfaz.mostrar_aviso("")
	await create_timer(0.25).timeout
	# El mapa también pausa y devuelve el estado anterior al cerrar.
	_encargos.desde_diccionario({"encargos": [{"id": String(IMPOSTOR.id), "estado": 1}]})
	await _capturar("seguimiento_la_voz")
	var mapa := escena.get_node("InterfazDelMapa/Mapa") as Control
	_interfaz.get_node("Atajos/Mapa").pressed.emit()
	await _esperar()
	_verificar(mapa.visible and paused and not _seguimiento.visible, "El mapa pausa y oculta el HUD")
	await _capturar("plano")
	await _accion(&"ver_mapa")
	_verificar(not mapa.visible and not paused and _seguimiento.visible, "Cerrar el mapa devuelve la exploración")
	await create_timer(0.25).timeout
	# Diálogo largo y breve: el panel también puede encogerse al cambiar de texto.
	var dialogo := _interfaz.get_node("Dialogo") as Control
	dialogo.preguntar("Pescador", LOMOS.oferta, ["Sí, te ayudo", "Ahora no"])
	dialogo._terminar_de_escribir()
	await _esperar()
	var caja_dialogo := dialogo.get_node("Caja") as Control
	var alto_largo := caja_dialogo.size.y
	_comprobar_pantalla(caja_dialogo, "Diálogo con opciones")
	await _capturar("dialogo")
	dialogo.get_node("Caja/Columna/Opciones").get_child(0).pressed.emit()
	dialogo._mostrar("Pescador", "Gracias.")
	await _esperar()
	_verificar(caja_dialogo.size.y <= alto_largo and caja_dialogo.size.y < 380.0, "El diálogo ajusta el alto a textos largos y breves")
	dialogo._mostrar("La Voz", IMPOSTOR.oferta)
	dialogo._terminar_de_escribir()
	await _capturar("dialogo_la_voz")
	dialogo.cerrar()
	await create_timer(0.25).timeout
	# Diario, controles y confirmación quedan dentro de la caja con desplazamiento.
	_interfaz.get_node("Atajos/Diario").pressed.emit()
	await _esperar()
	_verificar(pausa.visible and pausa.pagina == 0, "El atajo abre el diario")
	await _capturar("diario")
	pausa.mostrar_pagina(1)
	await _esperar()
	_verificar(caja.size.y <= 600.0, "Los controles no estiran la pausa")
	await _capturar("pausa_controles")
	pausa.mostrar_pagina(2)
	partida.get_node("Acciones/Borrar").pressed.emit()
	confirmacion.get_node("Botones/Confirmar").pressed.emit()
	for i in 20:
		await process_frame
	await _esperar()
	_verificar(not guardado.hay_partida() and not pausa.visible and not paused, "Confirmar borra el archivo y reinicia fuera de la pausa")
	_verificar(_encargos.historial().is_empty(), "La partida nueva tiene el diario vacío")
	await _probar_combate()


func _probar_combate() -> void:
	var combate := _interfaz.get_node("Combate") as Control
	var protagonista := current_scene.get_node("Jugador") as CharacterBody3D
	var rival := Node3D.new()
	protagonista.get_parent().add_child(rival)
	rival.global_position = protagonista.global_position + Vector3(2, 0, 0)
	await combate.iniciar(protagonista.modelo, rival, "Capitán Klaimyr", 36, 4, ManiobrasDeCombate.Estilo.CAPITAN, 15)
	await _esperar()
	_comprobar_pantalla(combate, "Combate")
	var datos_rival := combate.get_node("Columna/Vidas/Rival/Cabecera")
	var nombre := datos_rival.get_node("Nombre") as Label
	var cantidad := datos_rival.get_node("Cantidad") as Label
	_verificar(nombre.get_global_rect().end.x < cantidad.get_global_rect().position.x, "Nombre y vida del rival tienen espacio propio")
	await _capturar("combate")
	await combate._al_huir()
	await _capturar("combate_resultado")
	combate._cerrar()
	rival.queue_free()


func _probar_menu_principal() -> void:
	var guardado := root.get_node("Guardado")
	guardado.automatico = true
	change_scene_to_file(MENU)
	await scene_changed
	await _esperar()
	var acciones := current_scene.get_node("Inicio/Columna/Acciones")
	_verificar(acciones.get_node("Continuar").disabled, "Continuar se deshabilita sin archivo")
	_verificar(not _seguimiento.visible and not guardado.guardar(), "El menú oculta el HUD y no se guarda como escenario")
	_comprobar_pantalla(current_scene.get_node("Inicio"), "Menú principal")
	await _capturar("menu_sin_partida")
	acciones.get_node("Controles").pressed.emit()
	await _esperar()
	var controles := current_scene.get_node("Controles") as PanelContainer
	_verificar(controles.visible and controles.get_node("Columna/Interior/Acciones/Tabla").get_child_count() == 30,
		"El menú principal muestra la tabla de controles")
	_comprobar_pantalla(controles, "Controles del menú principal")
	await _capturar("menu_controles")
	await _accion(&"ui_cancel")
	_verificar(not controles.visible and acciones.visible, "Cancelar vuelve al menú principal")
	acciones.get_node("Nueva").pressed.emit()
	await scene_changed
	await _esperar_mundo()
	_verificar(current_scene.scene_file_path == SALBRUMA and _seguimiento.visible, "Nueva partida abre Salbruma desde cero")
	_encargos.aceptar(LOMOS)
	_encargos.contar(LOMOS.clave_de_conteo)
	_verificar(guardado.guardar(), "Escribir el progreso de prueba")
	change_scene_to_file(MENU)
	await scene_changed
	await _esperar()
	acciones = current_scene.get_node("Inicio/Columna/Acciones")
	_verificar(not acciones.get_node("Continuar").disabled, "Continuar se habilita con una partida")
	await _capturar("menu_con_partida")
	acciones.get_node("Nueva").pressed.emit()
	var confirmacion := current_scene.get_node("Inicio/Columna/Confirmacion") as Control
	_verificar(confirmacion.visible and root.gui_get_focus_owner() == confirmacion.get_node("Cancelar"),
		"Nueva partida advierte el borrado y enfoca Conservar partida")
	await _capturar("menu_confirmacion")
	await _accion(&"ui_cancel")
	_verificar(not confirmacion.visible and guardado.hay_partida(), "Cancelar conserva la partida del menú")
	_encargos.desde_diccionario({})
	acciones.get_node("Continuar").pressed.emit()
	await scene_changed
	await _esperar_mundo()
	_verificar(_encargos.avance_de(LOMOS) == 1 and current_scene.scene_file_path == SALBRUMA,
		"Continuar abre Salbruma con el progreso guardado")
	change_scene_to_file(MENU)
	await scene_changed
	var nuevo := current_scene.get_node("Inicio/Columna/Acciones/Nueva") as Button
	nuevo.pressed.emit()
	current_scene.get_node("Inicio/Columna/Confirmacion/Confirmar").pressed.emit()
	await scene_changed
	await _esperar_mundo()
	_verificar(not guardado.hay_partida() and _encargos.historial().is_empty(), "Confirmar borra la partida y abre el mundo desde cero")
	guardado.automatico = false
	DirAccess.remove_absolute(guardado.ruta.get_base_dir())


func _esperar_mundo() -> void:
	for i in 6:
		await physics_frame


func _comprobar_pantalla(panel: Control, nombre: String) -> void:
	var ventana := root.get_visible_rect()
	var rectangulo := panel.get_global_rect()
	_verificar(ventana.encloses(rectangulo), "%s queda dentro de la ventana (%s en %s)" % [nombre, rectangulo, ventana])


func _capturar(nombre: String) -> void:
	if _carpeta_de_capturas.is_empty():
		return
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	var ruta := _carpeta_de_capturas.path_join(nombre + ".png")
	_verificar(root.get_texture().get_image().save_png(ruta) == OK, "Captura guardada en " + ruta)


func _accion(accion: StringName) -> void:
	var evento := InputEventAction.new()
	evento.action = accion
	evento.pressed = true
	Input.parse_input_event(evento)
	await process_frame
	evento = InputEventAction.new()
	evento.action = accion
	evento.pressed = false
	Input.parse_input_event(evento)
	await _esperar()
