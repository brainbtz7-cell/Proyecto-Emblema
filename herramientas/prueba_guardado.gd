extends SceneTree
## Prueba de persistencia aislada: nunca lee ni escribe la partida de la persona.
## godot --headless --path . -s herramientas/prueba_guardado.gd -- /tmp/emblema_guardado

const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")
const GUARDIA := preload("res://encargos/puerto_junco_guardia_asaltantes.tres")
const DEFENSAS := preload("res://encargos/puerto_junco_jefe_defensas.tres")
const CUERO := preload("res://encargos/puerto_junco_pescador_cuero.tres")
const EMBOSCADA := preload("res://encargos/puerto_junco_guardia_emboscada.tres")
const RESCATE := preload("res://encargos/puerto_junco_tablon_rescate.tres")

var _fallos := 0
var _encargos: Node
var _guardado: Node


func _initialize() -> void:
	_correr.call_deferred()


func _correr() -> void:
	_encargos = root.get_node("Encargos")
	_guardado = root.get_node("Guardado")
	var argumentos := OS.get_cmdline_user_args()
	var carpeta := argumentos[0] if not argumentos.is_empty() else "/tmp/emblema_guardado"
	DirAccess.make_dir_recursive_absolute(carpeta)
	_guardado.ruta = carpeta.path_join("partida.json")
	if argumentos.size() > 1 and argumentos[1] == "reabrir":
		_verificar(_guardado.cargar(), "Cargar en un proceso nuevo antes de abrir el mundo")
		change_scene_to_file("res://mundo/salbruma/salbruma.tscn")
		await scene_changed
		await _esperar(8)
		var restaurado := current_scene.get_node("Jugador") as CharacterBody3D
		_verificar(_encargos.avance_de(LOMOS) == 2, "Recuperar el avance al reabrir")
		_verificar(FaunaAnomala.fichas == 1, "Recuperar las fichas al reabrir")
		_verificar(restaurado.nivel_de_prueba == 3 and restaurado.doble_salto, "Recuperar las mejoras del protagonista al reabrir")
		_guardado.borrar()
		print("REABRIR: ", "OK" if _fallos == 0 else "FALLO")
		quit(0 if _fallos == 0 else 1)
		return
	_guardado.borrar()
	var escena := load("res://mundo/salbruma/salbruma.tscn").instantiate() as Node3D
	root.add_child(escena)
	current_scene = escena
	await _esperar(12)
	var jugador := escena.get_node("Jugador") as CharacterBody3D
	var posicion_segura := jugador.global_position
	_encargos.aceptar(LOMOS)
	_encargos.contar(LOMOS.clave_de_conteo)
	_encargos.contar(LOMOS.clave_de_conteo)
	FaunaAnomala.registrar_caza("Uscita")
	if argumentos.size() > 1 and argumentos[1] == "cerrar":
		jugador.nivel_de_prueba = 3
		jugador.doble_salto = true
		_guardado.automatico = true
		_guardado._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		_verificar(_guardado.hay_partida(), "El cierre de la ventana guarda la partida")
		print("CERRAR: ", "OK" if _fallos == 0 else "FALLO")
		return
	_verificar(_guardado.guardar(), "Guardar en un archivo temporal")
	jugador.global_position += Vector3.UP * 5.0
	_verificar(_guardado.guardar(), "Guardar durante un salto")
	_encargos.desde_diccionario({})
	FaunaAnomala.desde_diccionario({})
	_verificar(await _cargar(), "Cargar el archivo escrito")
	escena = current_scene
	jugador = escena.get_node("Jugador")
	_verificar(_encargos.avance_de(LOMOS) == 2, "Recuperar el avance parcial")
	_verificar(_encargos.historial().size() == 1, "Recuperar el diario sin duplicados")
	_verificar(FaunaAnomala.fichas == 1 and FaunaAnomala.coleccion.get("Uscita") == 1, "Recuperar fichas y colección")
	_verificar(jugador.global_position.distance_to(posicion_segura) < 0.2, "Recuperar el apoyo seguro en vez del salto")
	# La misma ruta automática que usa el autoload, sin tocar user://.
	_guardado.automatico = true
	_completar(LOMOS)
	_completar(GUARDIA)
	_encargos.aceptar(DEFENSAS)
	_encargos.contar(DEFENSAS.clave_de_conteo, &"entrada")
	await _esperar(3)
	_verificar(_guardado.hay_partida(), "Guardado automático al avanzar")
	_encargos.desde_diccionario({})
	_verificar(await _cargar(), "Cargar defensas y entregas automáticas")
	_verificar(_encargos.estado_de(LOMOS) == _encargos.Estado.COMPLETADO, "Conservar la entrega de un encargo")
	_verificar(_encargos.contado(DEFENSAS, &"entrada"), "Conservar un punto único construido")
	_encargos.contar(DEFENSAS.clave_de_conteo, &"entrada")
	_verificar(_encargos.avance_de(DEFENSAS) == 1, "No volver a contar una defensa al cargar")
	_encargos.contar(DEFENSAS.clave_de_conteo, &"ribera")
	_encargos.contar(DEFENSAS.clave_de_conteo, &"muelle")
	_encargos.entregar(DEFENSAS)
	_completar(CUERO)
	_completar(EMBOSCADA)
	_encargos.aceptar(RESCATE)
	_encargos.contar(RESCATE.clave_de_conteo, &"liberar")
	await _esperar(3)
	_verificar(_guardado.guardar(), "Guardar durante el rescate")
	var datos_rescate: Dictionary = _encargos.a_diccionario()
	_encargos.desde_diccionario({})
	_verificar(await _cargar(), "Cargar durante el rescate")
	_verificar(_encargos.contado(RESCATE, &"liberar"), "El jefe sigue liberado tras cargar")
	escena = current_scene
	jugador = escena.get_node("Jugador")
	var jefe := escena.get_node("Rescate/Jefe") as Node3D
	_verificar(jefe.global_position.distance_to(jugador.global_position) < 3.0, "El acompañante retoma junto al protagonista")
	_verificar(_encargos.a_diccionario() == datos_rescate, "Conservar los siete encargos en orden")
	# Una copia válida permite recuperar un archivo truncado.
	var roto := FileAccess.open(_guardado.ruta, FileAccess.WRITE)
	roto.store_string("{archivo truncado")
	roto.close()
	_verificar(await _cargar(), "Recuperar la copia de seguridad")
	_verificar(_guardado.guardar(), "Confirmar la partida recuperada")
	var antes: Dictionary = _encargos.a_diccionario()
	DirAccess.remove_absolute(_guardado.ruta + ".bak")
	var incompatible := FileAccess.open(_guardado.ruta, FileAccess.WRITE)
	incompatible.store_string('{"version":999}')
	incompatible.close()
	_verificar(not _guardado.cargar(), "Rechazar una versión incompatible")
	_verificar(_encargos.a_diccionario() == antes, "Una carga inválida conserva la sesión")
	_guardado.ruta = carpeta.path_join("inexistente/partida.json")
	_verificar(not _guardado.guardar(), "Informar un fallo de escritura")
	_guardado.ruta = carpeta.path_join("partida.json")
	_verificar(_guardado.borrar(), "Borrar la partida y su respaldo")
	_verificar(not _guardado.hay_partida() and _encargos.historial().is_empty() and FaunaAnomala.fichas == 0, "Reiniciar todo el progreso")
	_guardado.automatico = false
	print("GUARDADO: ", "OK" if _fallos == 0 else "%d fallos" % _fallos)
	quit(0 if _fallos == 0 else 1)


func _completar(encargo: Encargo) -> void:
	_encargos.aceptar(encargo)
	for i in encargo.cantidad:
		_encargos.contar(encargo.clave_de_conteo)
	_encargos.entregar(encargo)


func _esperar(cuadros: int) -> void:
	for i in cuadros:
		await physics_frame


func _verificar(condicion: bool, descripcion: String) -> void:
	print("OK: " if condicion else "FALLO: ", descripcion)
	if not condicion:
		_fallos += 1


func _cargar() -> bool:
	var correcto: bool = _guardado.cargar()
	if correcto:
		await scene_changed
		await _esperar(5)
	return correcto
