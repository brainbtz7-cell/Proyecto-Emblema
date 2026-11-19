extends SceneTree
# Abre la isla de pruebas, espera unos cuadros y guarda capturas de pantalla.
# Uso: godot --path <proyecto> -s captura.gd -- <carpeta_de_salida> [modo]
# Modos: vista (por defecto), cenital, prueba.

var _salida := ""
var _modo := "vista"


func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	_salida = argumentos[0]
	if argumentos.size() > 1:
		_modo = argumentos[1]
	_correr()


func _correr() -> void:
	var escena: Node = load("res://mundo/terreno_de_prueba.tscn").instantiate()
	root.add_child(escena)
	await _esperar(20)

	var pixelado := root.get_node_or_null("Pixelado")
	print("Autoload Pixelado: ", pixelado != null)
	print("Ventana: ", root.size, "  escala 3D: ", root.scaling_3d_scale, "  modo: ", root.scaling_3d_mode)
	if pixelado:
		print("Tamaño de píxel: ", pixelado.tamano_de_pixel, "  interna: ", pixelado.resolucion_interna)

	var jugador: CharacterBody3D = escena.get_node("Jugador")
	print("Jugador en: ", jugador.global_position, "  en el suelo: ", jugador.is_on_floor())

	match _modo:
		"cenital":
			await _cenital(escena)
		"prueba":
			await _prueba(escena, jugador)
		"pixel":
			await _pixel(pixelado)
		"encargo":
			if not await _encargo(escena, jugador):
				quit(1)
				return
		"guardia":
			if not await _encargo_del_guardia(escena, jugador):
				quit(1)
				return
		"retrato":
			await _retrato(jugador)
		"anomala":
			await _anomala(escena, jugador)
		"arboles":
			await _arboles(escena, jugador)
		"arranque":
			print("al arrancar: escala ", root.scaling_3d_scale, " ventana ", root.size)
			await _medir_bloque()
			await _esperar(2)
			await _esperar(60)
			print("60 cuadros después: escala ", root.scaling_3d_scale, " ventana ", root.size)
			await _medir_bloque()
			await _esperar(2)
			root.scaling_3d_scale = 1.0 / 9.0
			await _esperar(4)
			print("tras reasignar 1/9:")
			await _medir_bloque()
			await _esperar(2)
			root.scaling_3d_scale = 0.5
			await _esperar(4)
			root.scaling_3d_scale = 1.0 / 9.0
			await _esperar(4)
			print("tras pasar por 0.5 y volver a 1/9:")
			await _medir_bloque()
			await _esperar(2)
		"escalas":
			for divisor in [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14]:
				root.scaling_3d_scale = 1.0 / divisor
				await _esperar(4)
				print("divisor ", divisor, "  escala leída ", root.scaling_3d_scale)
				await _medir_bloque()
				await _esperar(1)
		_:
			await _guardar("vista")
	quit()


func _cenital(escena: Node) -> void:
	var camara := Camera3D.new()
	camara.projection = Camera3D.PROJECTION_ORTHOGONAL
	camara.size = 140.0
	camara.far = 500.0
	escena.add_child(camara)
	camara.global_position = Vector3(0, 120, 0)
	camara.rotation_degrees = Vector3(-90, 0, 0)
	camara.current = true
	var entorno: WorldEnvironment = escena.get_node("Entorno")
	entorno.environment.fog_enabled = false
	escena.get_node("Nubes").visible = false
	await _esperar(10)
	await _guardar("cenital")
	var terreno = escena.get_node("Terreno")
	var linea := ""
	for z in range(-60, 61, 10):
		linea = ""
		for x in range(-60, 61, 10):
			linea += "%6.1f" % terreno.altura_en(x, z)
		print("z=%4d %s" % [z, linea])


func _prueba(_escena: Node, jugador: CharacterBody3D) -> void:
	var camara: Node3D = jugador.get_node("Camara")
	# 1. Caminar hacia adelante.
	var inicio := jugador.global_position
	Input.action_press("mover_adelante")
	await _esperar_fisica(60)
	Input.action_release("mover_adelante")
	await _esperar_fisica(20)
	var recorrido := jugador.global_position - inicio
	print("CAMINAR: recorrido ", recorrido, "  distancia horizontal %.2f" % Vector2(recorrido.x, recorrido.z).length())
	await _guardar("prueba_caminar")

	# 2. Salto simple.
	var base := jugador.global_position.y
	var maximo := base
	Input.action_press("saltar")
	for i in 70:
		await physics_frame
		maximo = maxf(maximo, jugador.global_position.y)
		if i == 12:
			await _guardar("prueba_salto")
	Input.action_release("saltar")
	print("SALTO SIMPLE: altura %.2f  (en el suelo al final: %s)" % [maximo - base, jugador.is_on_floor()])
	await _esperar_fisica(20)

	# 3. Doble salto: segundo impulso cerca del punto más alto.
	base = jugador.global_position.y
	maximo = base
	Input.action_press("saltar")
	for i in 110:
		await physics_frame
		maximo = maxf(maximo, jugador.global_position.y)
		if i == 18:
			Input.action_release("saltar")
		if i == 20:
			Input.action_press("saltar")
		if i == 28:
			await _guardar("prueba_doble_salto")
		# Un tercer intento no debe tener efecto.
		if i == 40:
			Input.action_release("saltar")
		if i == 42:
			Input.action_press("saltar")
	Input.action_release("saltar")
	print("DOBLE SALTO: altura %.2f  (en el suelo al final: %s)" % [maximo - base, jugador.is_on_floor()])

	# 4. Cámara: arrastrar con el botón derecho.
	var giro_antes := camara.rotation.y
	var movimiento := InputEventMouseMotion.new()
	movimiento.button_mask = MOUSE_BUTTON_MASK_RIGHT
	movimiento.position = Vector2(root.size) * 0.5
	movimiento.global_position = movimiento.position
	movimiento.relative = Vector2(200, 0)
	movimiento.screen_relative = Vector2(200, 0)
	Input.parse_input_event(movimiento)
	await _esperar(5)
	print("CÁMARA: giro %.3f rad" % (camara.rotation.y - giro_antes))
	await _guardar("prueba_camara")

	# 5. Recorrido de rocas: caer sobre el primer escalón y subir del 2 al 3 con doble salto.
	jugador.teletransportar(Vector3(1.0, 3.0, 44.0))
	await _esperar_fisica(60)
	print("ESCALON 1: ", jugador.global_position, "  en el suelo: ", jugador.is_on_floor())
	jugador.teletransportar(Vector3(4.0, 2.6, 48.0))
	await _esperar_fisica(40)
	print("ESCALON 2: ", jugador.global_position, "  en el suelo: ", jugador.is_on_floor())
	camara.rotation.y = 2.634  # mirando del escalón 2 al 3
	await _esperar(3)
	await _guardar("prueba_rocas")
	Input.action_press("mover_adelante")
	await _esperar_fisica(6)
	Input.action_press("saltar")
	for i in 140:
		await physics_frame
		if i == 19:
			Input.action_release("saltar")
		if i == 21:
			Input.action_press("saltar")
		if i == 60:
			Input.action_release("mover_adelante")
		if i > 30 and jugador.is_on_floor():
			break
	Input.action_release("saltar")
	Input.action_release("mover_adelante")
	await _esperar_fisica(20)
	print("ESCALON 3 (cima 4.8): ", jugador.global_position, "  en el suelo: ", jugador.is_on_floor())
	await _guardar("prueba_rocas_arriba")

	# 6. Caminar hasta el agua profunda: debe volver al último lugar seguro.
	jugador.teletransportar(Vector3(2.0, 3.0, 36.0))
	camara.rotation.y = PI
	await _esperar_fisica(60)
	Input.action_press("mover_izquierda")
	var minimo := jugador.global_position.y
	var reapariciones := 0
	var anterior := jugador.global_position
	for i in 1500:
		await physics_frame
		minimo = minf(minimo, jugador.global_position.y)
		if jugador.global_position.distance_to(anterior) > 1.0:
			reapariciones += 1
			print("REAPARICIÓN: de ", anterior, " a ", jugador.global_position)
			break
		anterior = jugador.global_position
	Input.action_release("mover_izquierda")
	print("AGUA: altura mínima alcanzada %.2f  reapariciones: %d" % [minimo, reapariciones])
	await _esperar(10)
	await _guardar("prueba_agua")


func _pixel(pixelado: Node) -> void:
	await _guardar("pixel_270")
	await _medir_bloque()
	for veces in 2:
		await _tecla(KEY_F2)
	print("Tras F2 x2: alto ", pixelado.alto_interno, "  píxel ", pixelado.tamano_de_pixel, "  interna ", pixelado.resolucion_interna)
	await _guardar("pixel_180")
	await _medir_bloque()
	for veces in 4:
		await _tecla(KEY_F3)
	print("Tras F3 x4: alto ", pixelado.alto_interno, "  píxel ", pixelado.tamano_de_pixel, "  interna ", pixelado.resolucion_interna)
	await _guardar("pixel_540")
	await _medir_bloque()


func _tecla(codigo: Key) -> void:
	for presionada in [true, false]:
		var evento := InputEventKey.new()
		evento.physical_keycode = codigo
		evento.keycode = codigo
		evento.pressed = presionada
		Input.parse_input_event(evento)
		await _esperar(3)


# Mide el ancho real de los bloques de color en una fila de la imagen final.
func _medir_bloque() -> void:
	await RenderingServer.frame_post_draw
	var imagen := root.get_texture().get_image()
	var conteo := {}
	for fila in [imagen.get_height() / 3, imagen.get_height() / 2, imagen.get_height() * 2 / 3]:
		var largo := 1
		for x in range(1, imagen.get_width()):
			if imagen.get_pixel(x, fila) == imagen.get_pixel(x - 1, fila):
				largo += 1
			else:
				conteo[largo] = conteo.get(largo, 0) + 1
				largo = 1
	var claves := conteo.keys()
	claves.sort()
	print("  Tramos más cortos (ancho: cantidad): ", claves.slice(0, 6).map(func(k): return "%d: %d" % [k, conteo[k]]))


func _accion(nombre: String) -> void:
	for presionada in [true, false]:
		var evento := InputEventAction.new()
		evento.action = nombre
		evento.pressed = presionada
		Input.parse_input_event(evento)
		await _esperar(2)


func _uscitas(escena: Node) -> Array:
	var lista := []
	for manada in [escena.get_node("ManadaEste"), escena.get_node("ManadaOeste")]:
		for hijo in manada.get_children():
			if hijo is CharacterBody3D and not hijo.is_queued_for_deletion():
				lista.append(hijo)
	return lista


func _iniciar_caza(escena: Node, jugador: CharacterBody3D) -> bool:
	var lista := _uscitas(escena)
	if lista.is_empty():
		return false
	var presa: Node3D = lista[0]
	jugador.teletransportar(presa.global_position + Vector3(1.55, 0.3, 0.0))
	await _esperar_fisica(6)
	await _accion("interactuar")
	return root.get_node("Interfaz/Combate").visible


func _cazar_uno(escena: Node, jugador: CharacterBody3D, guardar_victoria := false) -> bool:
	if not await _iniciar_caza(escena, jugador):
		return false
	return await _ganar_combate("combate_2_victoria" if guardar_victoria else "")


func _esperar_acciones() -> bool:
	var panel := root.get_node("Interfaz/Combate")
	var atacar: Button = panel.get_node("Columna/Acciones/Atacar")
	var continuar: Button = panel.get_node("Columna/Continuar")
	var limite := Time.get_ticks_msec() + 4000
	while atacar.disabled and not continuar.visible and Time.get_ticks_msec() < limite:
		await process_frame
	return not atacar.disabled or continuar.visible


func _ganar_combate(captura_victoria := "", captura_impacto := "") -> bool:
	var panel := root.get_node("Interfaz/Combate")
	var continuar: Button = panel.get_node("Columna/Continuar")
	var estado: Label = panel.get_node("Columna/Cabecera/Estado")
	var pronostico: Label = panel.get_node("Columna/Senal/Fila/Pronostico")
	var preparar: Button = panel.get_node("Columna/Acciones/Preparar")
	var gestos := panel.get_node("Gestos")
	for turno in 24:
		if not await _esperar_acciones():
			return false
		if continuar.visible:
			break
		if pronostico.text.begins_with("Rival · Embestida"):
			await _accion("combate_defender")
		elif not preparar.disabled and ("Coraza" in pronostico.text or "Guardia" in pronostico.text):
			await _accion("combate_preparar")
		else:
			await _accion("combate_atacar")
		if captura_impacto != "":
			await create_timer(0.36).timeout
			for efecto in gestos.get_children():
				if efecto is CPUParticles3D:
					await _guardar(captura_impacto)
					captura_impacto = ""
					break
	if estado.text != "Victoria":
		return false
	if captura_victoria != "":
		await create_timer(0.45).timeout
		await _guardar(captura_victoria)
	await _accion("ui_accept")
	await create_timer(0.22).timeout
	return not panel.visible


func _encargo(escena: Node, jugador: CharacterBody3D) -> bool:
	var encargos := root.get_node("Encargos")
	var interfaz := root.get_node("Interfaz")
	var pescador: Node3D = escena.get_node("Pescador")
	var encargo: Resource = pescador.encargos[0]
	var aviso: Label = interfaz.get_node("Aviso/Caja/Fila/Accion")
	var seguimiento: Label = interfaz.get_node("Seguimiento/Columna/Objetivo")
	var dialogo: Control = interfaz.get_node("Dialogo")
	var texto: Label = dialogo.get_node("Caja/Columna/Texto")
	var opciones: Node = dialogo.get_node("Caja/Columna/Opciones")
	await _esperar_fisica(20)
	print("INICIO: uscitas ", _uscitas(escena).size(), "  pescador en ", pescador.global_position,
		"  globo visible: ", pescador.get_node("Globo").visible, "  estado: ", encargos.estado_de(encargo))
	await _guardar("encargo_1_inicio")

	# Cazar antes de aceptar: no debe dar lomos (son objetos de misión).
	if not await _cazar_uno(escena, jugador) or encargos.avance_de(encargo) != 0:
		push_error("La caza sin encargo activo debe terminar sin otorgar lomos.")
		return false
	print("CAZA SIN ENCARGO: uscitas ", _uscitas(escena).size(), "  avance ", encargos.avance_de(encargo), "  estado ", encargos.estado_de(encargo))

	# Hablar con el pescador.
	jugador.teletransportar(pescador.global_position + Vector3(-1.2, 0.3, -1.0))
	await _esperar_fisica(8)
	print("AVISO junto al pescador: '", aviso.text, "'")
	await _guardar("encargo_2_aviso")
	await _accion("interactuar")
	await _esperar(20)
	print("DIÁLOGO abierto: ", dialogo.abierto, "  letras visibles: ", texto.visible_characters, " de ", texto.text.length(), "  jugador ocupado: ", interfaz.ocupada())
	await _guardar("encargo_3_dialogo")
	# Intentar moverse y saltar con el diálogo abierto no debe hacer nada.
	var antes := jugador.global_position
	Input.action_press("mover_adelante")
	Input.action_press("saltar")
	await _esperar_fisica(20)
	Input.action_release("mover_adelante")
	Input.action_release("saltar")
	print("BLOQUEO: se movió %.3f m con el diálogo abierto" % jugador.global_position.distance_to(antes))
	await _accion("interactuar")  # completa el texto
	await _esperar(4)
	print("TEXTO: ", texto.text)
	print("OPCIONES: ", opciones.get_children().map(func(b): return b.text), "  foco: ", root.gui_get_focus_owner())
	await _guardar("encargo_4_opciones")
	await _accion("ui_accept")  # elige la opción con foco: Aceptar
	await _esperar(6)
	print("JUSTO TRAS CERRAR: jugador ocupado ", interfaz.ocupada())
	await create_timer(0.4).timeout
	print("TRAS ACEPTAR: diálogo abierto ", dialogo.abierto, "  estado ", encargos.estado_de(encargo), "  seguimiento: ", seguimiento.text.replace("\n", " | "))

	# Defender y huir con el encargo activo conserva la presa y no da lomos.
	if not await _iniciar_caza(escena, jugador):
		push_error("No se pudo iniciar el combate de defensa y huida.")
		return false
	if not await _esperar_acciones():
		return false
	var panel := root.get_node("Interfaz/Combate")
	var cantidad_antes := _uscitas(escena).size()
	await _esperar_fisica(10)
	var sitio := jugador.global_position
	Input.action_press("mover_adelante")
	Input.action_press("saltar")
	await create_timer(0.45).timeout
	Input.action_release("mover_adelante")
	Input.action_release("saltar")
	if sitio.distance_to(jugador.global_position) > 0.10:
		push_error("El protagonista se desplazó durante el combate.")
		return false
	await _guardar("combate_1_turno")
	await _accion("ui_right")
	await _accion("ui_accept") # Defender.
	if not await _esperar_acciones():
		return false
	var estado: Label = panel.get_node("Columna/Cabecera/Estado")
	var relato: Label = panel.get_node("Columna/Relato")
	print("DEFENDER: ", relato.text.replace("\n", " | "))
	if not relato.text.begins_with("Te preparás"):
		push_error("No se pudo Defender desde el menú.")
		return false
	await _accion("combate_huir")
	if estado.text != "Huida":
		push_error("No se pudo Huir desde el menú.")
		return false
	await _accion("ui_accept") # Volver a explorar.
	await create_timer(0.22).timeout
	if panel.visible or _uscitas(escena).size() != cantidad_antes or encargos.avance_de(encargo) != 0:
		push_error("La huida debe conservar la presa y no otorgar lomos.")
		return false
	print("HUIDA: presa conservada y avance sin cambios.")

	# Cazar siete.
	for n in 7:
		if not await _cazar_uno(escena, jugador, n == 0) or encargos.avance_de(encargo) != n + 1:
			push_error("No se obtuvo exactamente un lomo tras la victoria.")
			return false
		print("  caza ", n + 1, ": avance ", encargos.avance_de(encargo), "  uscitas restantes ", _uscitas(escena).size())
	print("TRAS CAZAR 7: estado ", encargos.estado_de(encargo), "  seguimiento: ", seguimiento.text.replace("\n", " | "))
	await _guardar("encargo_5_cumplido")
	var lente: Camera3D = root.get_camera_3d()
	print("CÁMARA en ", lente.global_position, "  jugador en ", jugador.global_position)
	var pendientes: Array[Node] = [escena]
	while not pendientes.is_empty():
		var nodo: Node = pendientes.pop_back()
		pendientes.append_array(nodo.get_children(true))
		var visual := nodo as VisualInstance3D
		if visual and visual.is_visible_in_tree():
			var caja := visual.global_transform * visual.get_aabb()
			var cercano := caja.grow(3.0).has_point(lente.global_position)
			if cercano and not (nodo.get_parent() is CharacterBody3D and nodo.get_parent().name == "Jugador"):
				print("  cerca de la cámara: ", nodo.get_path(), "  caja ", caja)

	# Volver al poblado: la fauna se repone.
	jugador.teletransportar(pescador.global_position + Vector3(-1.2, 0.3, -1.0))
	await _esperar_fisica(12)
	print("DE VUELTA EN EL POBLADO: uscitas ", _uscitas(escena).size(), "  globo visible: ", pescador.get_node("Globo").visible)
	await _accion("interactuar")
	await _esperar(10)
	await _accion("interactuar")
	await _esperar(4)
	print("ENTREGA: ", texto.text)
	await _guardar("encargo_6_entrega")
	await _accion("interactuar")
	await _esperar(20)
	print("FINAL: estado ", encargos.estado_de(encargo), "  diálogo abierto ", dialogo.abierto, "  globo visible: ", pescador.get_node("Globo").visible,
		"  zona disponible: ", pescador.get_node("Interactuable").disponible, "  seguimiento: '", seguimiento.text, "'", "  aviso: '", aviso.text, "'")
	return encargos.estado_de(encargo) == encargos.Estado.COMPLETADO


func _encargo_del_guardia(escena: Node, jugador: CharacterBody3D) -> bool:
	var encargos := root.get_node("Encargos")
	var interfaz := root.get_node("Interfaz")
	var guardia: Node3D = escena.get_node("Guardia")
	var grupo: Node3D = escena.get_node("Asaltantes")
	var encargo: Resource = guardia.encargos[0]
	var panel: Control = interfaz.get_node("Combate")
	var estado: Label = panel.get_node("Columna/Cabecera/Estado")
	var nombre: Label = panel.get_node("Columna/Vidas/Rival/Nombre")
	var charla := guardia.global_position + Vector3(-1.15, 0.25, 0.85)
	jugador.teletransportar(charla)
	await _esperar_fisica(12)
	await _accion("interactuar")
	await _accion("interactuar")
	await _accion("ui_accept")
	await create_timer(0.25).timeout
	if encargos.estado_de(encargo) != encargos.Estado.ACTIVO:
		push_error("No se pudo aceptar el encargo del guardia.")
		return false

	# Un asaltante ignora a un protagonista de nivel superior.
	var rival := grupo.get_child(0) as Node3D
	jugador.nivel_de_prueba = 2
	jugador.teletransportar(rival.global_position + Vector3(1.95, 0.35, 0.0))
	await _esperar_fisica(10)
	if panel.visible:
		push_error("Un enemigo de nivel inferior inició combate.")
		return false
	jugador.nivel_de_prueba = 1
	await _esperar_fisica(6)
	if not panel.visible or nombre.text != "Asaltante Klaimyr":
		push_error("El asaltante de igual nivel no inició combate.")
		return false
	print("HOSTILIDAD: nivel inferior ignora, nivel igual inicia combate.")
	if not await _esperar_acciones():
		return false
	await _accion("combate_huir")
	if estado.text != "Huida":
		push_error("No se pudo huir del Asaltante Klaimyr.")
		return false
	await _accion("ui_accept")
	await create_timer(0.3).timeout
	if encargos.avance_de(encargo) != 0:
		push_error("Huir contó como derrota de un asaltante.")
		return false

	for numero in 7:
		if numero == 0:
			jugador.teletransportar(charla)
			await _esperar_fisica(12)
		rival = grupo.get_child(0) as Node3D
		jugador.teletransportar(rival.global_position + Vector3(1.95, 0.35, 0.0))
		await _esperar_fisica(12)
		var es_primero := numero == 0
		if not panel.visible or not await _ganar_combate(
			"klaimyr_victoria" if es_primero else "", "klaimyr_impacto" if es_primero else ""
		):
			push_error("No se pudo derrotar al Asaltante Klaimyr.")
			return false
		if encargos.avance_de(encargo) != numero + 1:
			push_error("La victoria no contó exactamente una derrota.")
			return false
		print("ASALTANTES: ", encargos.avance_de(encargo), " / ", encargo.cantidad)

	jugador.teletransportar(charla)
	await _esperar_fisica(10)
	await _accion("interactuar")
	await _accion("interactuar")
	await _guardar("guardia_entrega")
	await _accion("interactuar")
	print("GUARDIA: estado ", encargos.estado_de(encargo), "  asaltantes repuestos ", grupo.get_child_count())
	return encargos.estado_de(encargo) == encargos.Estado.COMPLETADO


# Lanzar con "--anomalia-forzada" para que todos los animales sean Anómalos.
func _anomala(escena: Node, jugador: CharacterBody3D) -> void:
	await _esperar_fisica(20)
	var lista := _uscitas(escena)
	var anomalos := lista.filter(func(a): return a.anomala)
	print("ANÓMALOS: %d de %d  probabilidad %.4f" % [anomalos.size(), lista.size(), FaunaAnomala.probabilidad])
	if lista.is_empty():
		return
	var presa: CharacterBody3D = lista[0]
	print("  nombre en combate: ", presa.nombre_de_combate, "  rasgo: ", presa.get_node_or_null("Modelo/RasgoAnomalo") != null)
	# Retrato del animal.
	var camara: Node3D = jugador.get_node("Camara")
	jugador.teletransportar(presa.global_position + Vector3(0.0, 0.3, 4.0))
	presa.set_physics_process(false)
	var lente := Camera3D.new()
	escena.add_child(lente)
	lente.global_position = presa.global_position + Vector3(2.4, 1.6, 2.4)
	lente.look_at(presa.global_position + Vector3.UP * 0.7)
	lente.fov = 40.0
	lente.current = true
	await _esperar_fisica(30)
	await _guardar("anomala_1_retrato")
	lente.queue_free()
	await _esperar(2)
	presa.set_physics_process(true)
	# Cazarlo.
	var antes := FaunaAnomala.fichas
	var gano := await _cazar_uno(escena, jugador)
	await _esperar(3)
	var aviso := root.get_node_or_null("AvisoAnomalo")
	print("CAZA: ganó %s  fichas %d -> %d  colección %s  aviso visible %s" % [gano, antes, FaunaAnomala.fichas, FaunaAnomala.coleccion, aviso != null and aviso.get_child(0).visible])
	await _guardar("anomala_2_aviso")
	var datos := FaunaAnomala.a_diccionario()
	FaunaAnomala.desde_diccionario({})
	FaunaAnomala.desde_diccionario(datos)
	print("GUARDADO ida y vuelta: ", FaunaAnomala.a_diccionario() == datos, "  ", datos)


func _retrato(jugador: CharacterBody3D) -> void:
	var camara: Node3D = jugador.get_node("Camara")
	var brazo: SpringArm3D = camara.get_node("Brazo")
	camara.distancia = 3.6
	brazo.rotation.x = deg_to_rad(-8.0)
	root.get_node("Interfaz").visible = false
	# De frente, quieto.
	camara.rotation.y = 0.45
	await _esperar(50)
	await _guardar("retrato_1_frente")
	# De espaldas, quieto.
	camara.rotation.y = PI - 0.5
	await _esperar(30)
	await _guardar("retrato_2_espalda")
	# Caminando hacia la cámara.
	camara.rotation.y = 0.45
	await _esperar(10)
	Input.action_press("mover_atras")
	await _esperar_fisica(34)
	await _guardar("retrato_3_caminando")
	Input.action_release("mover_atras")
	await _esperar_fisica(30)
	# De costado, corriendo.
	Input.action_press("mover_derecha")
	await _esperar_fisica(40)
	await _guardar("retrato_4_costado")
	Input.action_release("mover_derecha")
	await _esperar_fisica(30)
	# Salto: subiendo y cayendo.
	Input.action_press("saltar")
	await _esperar_fisica(12)
	await _guardar("retrato_5_subiendo")
	await _esperar_fisica(14)
	await _guardar("retrato_6_cayendo")
	Input.action_release("saltar")
	await _esperar_fisica(30)
	# Doble salto: a mitad de la vuelta.
	Input.action_press("saltar")
	await _esperar_fisica(18)
	Input.action_release("saltar")
	await _esperar_fisica(2)
	Input.action_press("saltar")
	await _esperar_fisica(9)
	await _guardar("retrato_7_vuelta")
	Input.action_release("saltar")


func _arboles(escena: Node, jugador: CharacterBody3D) -> void:
	var arboleda: Node3D = escena.get_node("Arboleda")
	var camara: Node3D = jugador.get_node("Camara")
	var brazo: SpringArm3D = camara.get_node("Brazo")
	var lista := arboleda.get_children()
	print("ÁRBOLES plantados: ", lista.size())
	if lista.is_empty():
		return
	var alturas := lista.map(func(a): return a.global_position.y)
	print("  alturas del suelo: de %.1f a %.1f" % [alturas.min(), alturas.max()])
	# El más cercano al inicio y al pescador.
	var inicio := Vector2(jugador.global_position.x, jugador.global_position.z)
	var pescador: Node3D = escena.get_node("Pescador")
	var cerca_inicio := INF
	var cerca_pescador := INF
	for a in lista:
		var lugar := Vector2(a.global_position.x, a.global_position.z)
		cerca_inicio = minf(cerca_inicio, lugar.distance_to(inicio))
		cerca_pescador = minf(cerca_pescador, lugar.distance_to(Vector2(pescador.global_position.x, pescador.global_position.z)))
	print("  árbol más cercano al inicio: %.1f m   al pescador: %.1f m" % [cerca_inicio, cerca_pescador])
	await _guardar("arboles_1_inicio")

	# Elegir un árbol con espacio al sur para caminar hacia él.
	var arbol: Node3D = lista[lista.size() / 2]
	var tronco := arbol.global_position
	# Vista general de un manchón.
	jugador.teletransportar(tronco + Vector3(0.0, 0.5, 7.0))
	camara.rotation.y = 0.0  # mirando hacia -Z, hacia el árbol
	brazo.rotation.x = deg_to_rad(-12.0)
	await _esperar_fisica(40)
	await _guardar("arboles_2_manchon")

	# Caminar derecho contra el tronco: no debe atravesarlo.
	jugador.teletransportar(tronco + Vector3(0.0, 0.5, 3.0))
	await _esperar_fisica(30)
	Input.action_press("mover_adelante")
	var minima := INF
	for i in 120:
		await physics_frame
		var d := Vector2(jugador.global_position.x - tronco.x, jugador.global_position.z - tronco.z).length()
		minima = minf(minima, d)
	Input.action_release("mover_adelante")
	print("TRONCO: distancia mínima al centro %.2f m  (jugador en z=%.2f, tronco en z=%.2f)" % [minima, jugador.global_position.z, tronco.z])
	await _guardar("arboles_3_contra_el_tronco")

	# La cámara metida en la copa: el follaje debe llenarse de huecos.
	jugador.teletransportar(tronco + Vector3(0.0, 0.5, -2.2))
	camara.rotation.y = 0.0
	brazo.rotation.x = deg_to_rad(-24.0)
	camara.distancia = 6.0
	await _esperar_fisica(50)
	var lente: Camera3D = root.get_camera_3d()
	print("CÁMARA en ", lente.global_position, "  tronco en ", tronco)
	await _guardar("arboles_4_camara_en_la_copa")

	# El protagonista detrás de una copa, con la cámara lejos: debe abrirse una ventana.
	camara.distancia = 11.0
	brazo.rotation.x = deg_to_rad(-10.0)
	await _esperar_fisica(60)
	print("VENTANA: cámara en ", root.get_camera_3d().global_position, "  jugador en ", jugador.global_position)
	await _guardar("arboles_4b_ventana")

	# Desde arriba.
	var cenital := Camera3D.new()
	cenital.projection = Camera3D.PROJECTION_ORTHOGONAL
	cenital.size = 110.0
	cenital.far = 500.0
	escena.add_child(cenital)
	cenital.global_position = Vector3(0, 120, 0)
	cenital.rotation_degrees = Vector3(-90, 0, 0)
	cenital.current = true
	escena.get_node("Entorno").environment.fog_enabled = false
	escena.get_node("Nubes").visible = false
	root.get_node("Interfaz").visible = false
	await _esperar(10)
	await _guardar("arboles_5_cenital")


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await process_frame


func _esperar_fisica(cuadros: int) -> void:
	for i in cuadros:
		await physics_frame


func _guardar(nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("Sin ventana: se omite la captura ", nombre)
		return
	await RenderingServer.frame_post_draw
	var imagen := root.get_texture().get_image()
	# Se reduce para que el archivo sea liviano y fácil de revisar.
	var ancho := 1600
	imagen.resize(ancho, ancho * imagen.get_height() / imagen.get_width(), Image.INTERPOLATE_NEAREST)
	var ruta := _salida.path_join(nombre + ".png")
	imagen.save_png(ruta)
	print("Captura: ", ruta, "  ", imagen.get_size())
