extends SceneTree
## Verifica el alto del HUD después de redistribuir textos y de abrir paneles.
## godot --headless --path . -s herramientas/prueba_interfaz.gd

const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")
const GUARDIA := preload("res://encargos/puerto_junco_guardia_asaltantes.tres")

var _fallos := 0
var _encargos: Node
var _interfaz: Node
var _seguimiento: Control


func _initialize() -> void:
	_correr.call_deferred()


func _correr() -> void:
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
	var escena: Node = load("res://mundo/salbruma/salbruma.tscn").instantiate()
	root.add_child(escena)
	current_scene = escena
	await _esperar()
	var guardado := root.get_node("Guardado")
	DirAccess.make_dir_recursive_absolute("/tmp/emblema_interfaz")
	guardado.ruta = "/tmp/emblema_interfaz/partida.json"
	guardado.borrar()
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
	partida.get_node("Acciones/Guardar").pressed.emit()
	await _esperar()
	_verificar(guardado.hay_partida(), "Guardar desde el botón del menú")
	partida.get_node("Acciones/Borrar").pressed.emit()
	await _esperar()
	var confirmacion := partida.get_node("Confirmacion") as Control
	_verificar(confirmacion.visible, "El borrado requiere confirmar en el juego")
	_verificar(root.gui_get_focus_owner() == confirmacion.get_node("Botones/Cancelar"), "Conservar partida recibe el foco inicial")
	await _accion(&"pausar")
	_verificar(not confirmacion.visible and pausa.visible and guardado.hay_partida(), "Esc cancela el borrado sin cerrar la pausa")
	await _accion(&"pausar")
	_verificar(not pausa.visible and not paused and _seguimiento.visible, "Otro Esc vuelve a explorar")
	await create_timer(0.25).timeout
	# El mapa también pausa y devuelve el estado anterior al cerrar.
	var mapa := escena.get_node("InterfazDelMapa/Mapa") as Control
	_interfaz.get_node("Atajos/Mapa").pressed.emit()
	await _esperar()
	_verificar(mapa.visible and paused and not _seguimiento.visible, "El mapa pausa y oculta el HUD")
	await _accion(&"ver_mapa")
	_verificar(not mapa.visible and not paused and _seguimiento.visible, "Cerrar el mapa devuelve la exploración")
	await create_timer(0.25).timeout
	# Diálogo largo y breve: el panel también puede encogerse al cambiar de texto.
	var dialogo := _interfaz.get_node("Dialogo") as Control
	dialogo._mostrar("Pescador", LOMOS.oferta)
	await _esperar()
	var caja_dialogo := dialogo.get_node("Caja") as Control
	var alto_largo := caja_dialogo.size.y
	dialogo._mostrar("Pescador", "Gracias.")
	await _esperar()
	_verificar(caja_dialogo.size.y <= alto_largo and caja_dialogo.size.y < 380.0, "El diálogo ajusta el alto a textos largos y breves")
	dialogo.cerrar()
	await create_timer(0.25).timeout
	# Diario, controles y confirmación quedan dentro de la caja con desplazamiento.
	_interfaz.get_node("Atajos/Diario").pressed.emit()
	await _esperar()
	_verificar(pausa.visible and pausa.pagina == 0, "El atajo abre el diario")
	pausa.mostrar_pagina(1)
	await _esperar()
	_verificar(caja.size.y <= 600.0, "Los controles no estiran la pausa")
	pausa.mostrar_pagina(2)
	partida.get_node("Acciones/Borrar").pressed.emit()
	confirmacion.get_node("Botones/Confirmar").pressed.emit()
	for i in 20:
		await process_frame
	await _esperar()
	_verificar(not guardado.hay_partida() and not pausa.visible and not paused, "Confirmar borra el archivo y reinicia fuera de la pausa")
	_verificar(_encargos.historial().is_empty(), "La partida nueva tiene el diario vacío")


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
