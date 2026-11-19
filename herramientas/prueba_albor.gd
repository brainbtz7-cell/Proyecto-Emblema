extends SceneTree
# Prueba el viaje a Puerto Albor: visión de La Voz, llegada y capturas.
# Uso: godot --path . -s herramientas/prueba_albor.gd -- <carpeta_de_salida>

var _salida := ""


func _initialize() -> void:
	_salida = OS.get_cmdline_user_args()[0]
	_correr()


func _correr() -> void:
	var escena: Node = load("res://mundo/salbruma/salbruma.tscn").instantiate()
	root.add_child(escena)
	await _cuadros(30)
	var encargos := root.get_node("Encargos")
	var interfaz := root.get_node("Interfaz")
	var dialogo = interfaz.dialogo
	var marea: Encargo = load("res://encargos/puerto_junco_ultima_marea.tres")
	var mision: Encargo = load("res://encargos/la_voz_desenmascara_al_impostor.tres")
	var jugador: CharacterBody3D = escena.get_node("Jugador")

	# Se simula que La última marea ya está cumplida (solo para la prueba).
	for requisito in marea.requisitos:
		encargos._estados[requisito] = encargos.Estado.COMPLETADO
	encargos._estados[marea.id] = encargos.Estado.CUMPLIDO
	encargos._en_curso.append(marea)
	encargos.entregar(marea)
	await _cuadros(40)
	print("VISIÓN: diálogo abierto ", dialogo.abierto, "  texto: ", dialogo.get_node("%Texto").text if dialogo.has_node("%Texto") else "?")
	await _guardar("albor_1_vision")
	await _pulsar("interactuar")
	await _cuadros(4)
	await _pulsar("interactuar")
	await _cuadros(20)
	print("TRAS LA VISIÓN: estado de la misión ", encargos.estado_de(mision), " (1 = activa)  diálogo abierto ", dialogo.abierto)

	# Recorrido del sendero en saltos: comprobar que hay suelo y que no es una pared.
	var ruta: Array[Vector2] = load("res://mundo/salbruma/trazado_salbruma.gd").HACIA_ALBOR
	var terreno = escena.get_node("Terreno")
	var peor := 0.0
	for i in range(1, ruta.size()):
		for k in 10:
			var a: Vector2 = ruta[i - 1].lerp(ruta[i], k / 10.0)
			var b: Vector2 = ruta[i - 1].lerp(ruta[i], (k + 1) / 10.0)
			var pendiente := absf(terreno.altura_en(b.x, b.y) - terreno.altura_en(a.x, a.y)) / maxf(a.distance_to(b), 0.01)
			if pendiente > 0.3:
				print("  empinado en ", a, " -> ", b, "  %.0f %%" % (pendiente * 100.0))
			peor = maxf(peor, pendiente)
	print("SENDERO: pendiente máxima %.0f %%" % (peor * 100.0))

	# Faros.
	jugador.teletransportar(Vector3(22, terreno.altura_en(22, -133) + 0.2, -133))
	jugador.get_node("Camara").rotation.y = deg_to_rad(-120)
	await _fisica(60)
	await _guardar("albor_2_faros")

	# Llegada a Albor.
	jugador.teletransportar(Vector3(64, terreno.altura_en(64, -160) + 0.2, -160))
	jugador.get_node("Camara").rotation.y = deg_to_rad(-90)
	await _fisica(60)
	print("LLEGADA: estado de la misión ", encargos.estado_de(mision), " (3 = completada)  diálogo abierto ", dialogo.abierto)
	await _guardar("albor_3_llegada")
	await _pulsar("interactuar")
	await _cuadros(4)
	await _pulsar("interactuar")
	await _fisica(40)
	await _guardar("albor_4_pueblo")
	quit()


func _pulsar(accion: String) -> void:
	for presionada in [true, false]:
		var evento := InputEventAction.new()
		evento.action = accion
		evento.pressed = presionada
		Input.parse_input_event(evento)
		await _cuadros(2)


func _cuadros(n: int) -> void:
	for i in n:
		await process_frame


func _fisica(n: int) -> void:
	for i in n:
		await physics_frame


func _guardar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := root.get_texture().get_image()
	imagen.resize(1600, 1600 * imagen.get_height() / imagen.get_width(), Image.INTERPOLATE_NEAREST)
	imagen.save_png(_salida.path_join(nombre + ".png"))
