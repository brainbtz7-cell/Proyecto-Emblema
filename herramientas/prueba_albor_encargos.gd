extends SceneTree
## Recorre la primera tanda por diálogo, bote, recolección y combate reales.
## godot --headless --path . -s herramientas/prueba_albor_encargos.gd
## Con ventana: agregar -- <carpeta_de_capturas>.

const ESCENA := "res://mundo/salbruma/salbruma.tscn"
const GRUTA := preload("res://encargos/puerto_albor_gruta_olvidada.tres")
const ARENA := preload("res://encargos/puerto_albor_arena.tres")
const CAPARAZONES := preload("res://encargos/puerto_albor_caparazones.tres")
const IMPOSTOR := preload("res://encargos/la_voz_desenmascara_al_impostor.tres")
const MAREA := preload("res://encargos/puerto_junco_ultima_marea.tres")

var _jugador: CharacterBody3D
var _terreno: Node3D
var _interfaz: Node
var _encargos: Node
var _salida := ""


func _initialize() -> void:
	_correr.call_deferred()


func _correr() -> void:
	seed(31277)
	if DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().is_empty():
		_salida = OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(_salida)
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1440, 900)
	_interfaz = root.get_node("Interfaz")
	_encargos = root.get_node("Encargos")
	change_scene_to_file(ESCENA)
	await scene_changed
	await _fisica(35)
	_enlazar()
	for nombre in ["HabitanteDeAlbor", "Barquero", "Pescadora"]:
		if not _verificar(not current_scene.get_node(nombre + "/Interactuable").disponible, "Oferta bloqueada antes del viaje · " + nombre):
			return
	if not _verificar(current_scene.get_node("BloqueoGruta").visible, "Gruta cerrada antes del encargo"):
		return
	if not _verificar(not current_scene.get_node("Arena1").visible, "Arena oculta sin encargo activo"):
		return
	if not _verificar(not current_scene.get_node("BoteAlCayo/Interactuable").disponible, "Viaje bloqueado antes del encargo"):
		return
	# Preparación de las siete entregas de Junco. Desde aquí se juega el viaje.
	for recurso in DirAccess.get_files_at("res://encargos"):
		if recurso.begins_with("puerto_junco_") and recurso.ends_with(".tres"):
			var encargo: Resource = load("res://encargos/" + recurso)
			if encargo != MAREA:
				_encargos._estados[encargo.id] = 3
	_encargos._estados[MAREA.id] = 2
	_encargos._en_curso.append(MAREA)
	_encargos.entregar(MAREA)
	if not await _esperar(func() -> bool: return _interfaz.dialogo.abierto, "Visión de La Voz"):
		return
	await _cerrar_dialogo()
	if not _verificar(_encargos.estado_de(IMPOSTOR) == 1, "Misión dorada recibida"):
		return
	_colocar(Vector3(64, 0, -160))
	await _fisica(20)
	await _cerrar_dialogo()
	for nombre in ["HabitanteDeAlbor", "Barquero", "Pescadora"]:
		if not _verificar(current_scene.get_node(nombre + "/Interactuable").disponible, "Oferta simultánea · " + nombre):
			return
	if not await _hablar("Barquero", ARENA, false):
		return
	if not await _hablar("Pescadora", CAPARAZONES, false):
		return
	if not await _hablar("HabitanteDeAlbor", GRUTA, false):
		return
	await _fisica(3)
	if not _verificar(not current_scene.get_node("BloqueoGruta").visible and current_scene.get_node("BloqueoGruta/Forma").disabled, "Aceptar abre la colisión y la boca de la gruta"):
		return
	if not await _viajar("BoteAlCayo", "LlegadaCayo"):
		return
	await _vista("cayo_muelle", Vector3(123, 13, -172), Vector3(111, 0, -185))
	if not _verificar(current_scene.get_node("Krabchios").get_child_count() >= 5, "Hay cinco Krabchio cazables"):
		return
	# Se recarga con una arena reunida: el mismo montículo no puede duplicarse.
	if not await _recoger("Arena1", 1):
		return
	var guardado := root.get_node("Guardado")
	var temporal := "/tmp/emblema_albor_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(temporal)
	guardado.ruta = temporal.path_join("partida.json")
	if not _verificar(guardado.guardar(), "Guardar avance parcial de arena"):
		return
	if not _verificar(guardado.cargar(), "Cargar avance parcial"):
		return
	await scene_changed
	await _fisica(32)
	_enlazar()
	if not _verificar(not current_scene.get_node("Arena1").visible and current_scene.get_node("Arena2").visible, "La arena recogida sigue oculta al continuar"):
		return
	if not await _recoger("Arena2", 2) or not await _recoger("Arena3", 3):
		return
	for i in 5:
		if not await _cazar():
			return
		if not _verificar(_encargos.avance_de(CAPARAZONES) == i + 1, "Un caparazón por Krabchio · %d/5" % (i + 1)):
			return
	if not await _viajar("BoteAAlbor", "LlegadaAlbor"):
		return
	if not await _hablar("Barquero", ARENA, true) or not await _hablar("Pescadora", CAPARAZONES, true):
		return
	# Cruza físicamente la entrada y llega al fondo, sin simular su contador.
	var boca: Node3D = current_scene.get_node("BloqueoGruta")
	_jugador.teletransportar(boca.global_position + Vector3(0, 0.15, 3.0))
	_jugador.camara.rotation.y = 0.0
	await _fisica(12)
	await _vista("gruta_entrada", boca.global_position + Vector3(4.5, 4.2, 8), boca.global_position + Vector3(0, 1.2, -3))
	Input.action_press("mover_adelante")
	for i in 190:
		await physics_frame
		if _encargos.avance_de(GRUTA) == 1:
			break
	Input.action_release("mover_adelante")
	await _fisica(12)
	if not _verificar(_encargos.avance_de(GRUTA) == 1, "Atravesar la gruta activa el objetivo del fondo"):
		print("Posición al detenerse ", _jugador.global_position, " · fondo ", current_scene.get_node("FondoGruta").global_position)
		return
	await _foto("gruta_fondo")
	if not await _hablar("HabitanteDeAlbor", GRUTA, true):
		return
	print("ALBOR PRIMERA TANDA · OK")
	current_scene.queue_free()
	await process_frame
	await process_frame
	quit()


func _enlazar() -> void:
	_jugador = current_scene.get_node("Jugador")
	_jugador.nivel_de_prueba = 100
	_terreno = current_scene.get_node("Terreno")


func _hablar(nombre: String, encargo: Resource, entregar: bool) -> bool:
	var habitante: Node3D = current_scene.get_node(nombre)
	_colocar(habitante.global_position + Vector3(-1.15, 0, -0.8))
	await _fisica(12)
	await _pulsar("interactuar")
	if not _verificar(_interfaz.dialogo.abierto, "Diálogo de " + nombre):
		return false
	await _pulsar("interactuar")
	await _pulsar("interactuar" if entregar else "ui_accept")
	await _reposo()
	return _verificar(_encargos.estado_de(encargo) == (3 if entregar else 1), ("Entregado · " if entregar else "Aceptado · ") + encargo.titulo)


func _viajar(bote: String, llegada: String) -> bool:
	var nodo: Node3D = current_scene.get_node(bote)
	# Los muelles están sobre el agua: usar la altura real de la pasarela.
	_jugador.teletransportar(nodo.global_position + Vector3(0, 0.15, 0))
	await _fisica(10)
	await _pulsar("interactuar")
	if not _verificar(_interfaz.en_travesia and not nodo.get_node("Interactuable").disponible, "Travesía bloquea interacciones repetidas"):
		return false
	var antes := _jugador.global_position
	Input.action_press("mover_adelante")
	await create_timer(0.10).timeout
	Input.action_release("mover_adelante")
	if not _verificar(antes.distance_to(_jugador.global_position) < 0.08, "No camina durante el fundido del bote"):
		return false
	await create_timer(1.5).timeout
	var destino: Node3D = current_scene.get_node(llegada)
	return _verificar(not _interfaz.en_travesia and _jugador.global_position.distance_to(destino.global_position) < 1.0, "Viaje completado · " + bote)


func _recoger(nombre: String, cantidad: int) -> bool:
	var arena: Node3D = current_scene.get_node(nombre)
	if not _verificar(arena.visible, "Arena disponible · " + nombre):
		return false
	_colocar(arena.global_position + Vector3(0.65, 0, 0))
	await _fisica(10)
	await _pulsar("interactuar")
	return _verificar(not arena.visible and _encargos.avance_de(ARENA) == cantidad, "Recogida única · " + nombre)


func _cazar() -> bool:
	var manada: Node3D = current_scene.get_node("Krabchios")
	if manada.get_child_count() == 0:
		return _verificar(false, "Quedan Krabchio")
	var rival: CharacterBody3D = manada.get_child(0)
	_colocar(rival.global_position + Vector3(1.0, 0, 0))
	await _fisica(8)
	await _pulsar("interactuar")
	var panel: Control = _interfaz.combate
	if not _verificar(panel.visible, "Combate con Krabchio por interacción"):
		return false
	var continuar: Button = panel.get_node("Columna/Continuar")
	var atacar: Button = panel.get_node("Columna/Acciones/Atacar")
	for i in 24:
		if not await _esperar(func() -> bool: return continuar.visible or not atacar.disabled, "Turno de combate"):
			return false
		if continuar.visible:
			break
		var pronostico: Label = panel.get_node("Columna/Senal/Fila/Pronostico")
		var preparar: Button = panel.get_node("Columna/Acciones/Preparar")
		if "Embestida" in pronostico.text:
			await _pulsar("combate_defender")
		elif not preparar.disabled and ("Coraza" in pronostico.text or "Guardia" in pronostico.text):
			await _pulsar("combate_preparar")
		else:
			await _pulsar("combate_atacar")
	if not _verificar(panel.get_node("Columna/Cabecera/Estado").text == "Victoria", "Victoria del Krabchio"):
		return false
	await _pulsar("ui_accept")
	await _reposo()
	return true


func _cerrar_dialogo() -> void:
	for i in 4:
		if _interfaz.dialogo.abierto:
			await _pulsar("interactuar")
	await _reposo()


func _colocar(punto: Vector3) -> void:
	punto.y = _terreno.altura_en(punto.x, punto.z) + 0.15
	_jugador.teletransportar(punto)


func _pulsar(accion: String) -> void:
	for presionado in [true, false]:
		var evento := InputEventAction.new()
		evento.action = accion
		evento.pressed = presionado
		Input.parse_input_event(evento)
		for i in 4:
			await process_frame


func _fisica(n: int) -> void:
	for i in n:
		await physics_frame


func _reposo() -> void:
	await create_timer(0.24).timeout


func _esperar(condicion: Callable, descripcion: String) -> bool:
	var fin := Time.get_ticks_msec() + 4500
	while not condicion.call() and Time.get_ticks_msec() < fin:
		await process_frame
	return _verificar(condicion.call(), descripcion)


func _verificar(condicion: bool, descripcion: String) -> bool:
	print("OK · " if condicion else "FALLO · ", descripcion)
	if not condicion:
		quit(1)
	return condicion


func _foto(nombre: String) -> void:
	if _salida.is_empty():
		return
	await RenderingServer.frame_post_draw
	var imagen := root.get_texture().get_image()
	imagen.resize(1440, roundi(1440.0 * imagen.get_height() / imagen.get_width()), Image.INTERPOLATE_NEAREST)
	_verificar(imagen.save_png(_salida.path_join(nombre + ".png")) == OK, "Captura " + nombre)


func _vista(nombre: String, origen: Vector3, destino: Vector3) -> void:
	if _salida.is_empty():
		return
	var camara := Camera3D.new()
	current_scene.add_child(camara)
	camara.global_position = origen
	camara.look_at(destino)
	camara.make_current()
	await _fisica(5)
	await _foto(nombre)
	camara.queue_free()
	_jugador.get_node("Camara/Brazo/Lente").make_current()
