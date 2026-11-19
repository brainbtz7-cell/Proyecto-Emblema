extends Node
## Coordina sistemas serializables. El archivo se reemplaza solo tras escribirlo entero.

signal cambiado
signal resultado(correcto: bool, mensaje: String)

const VERSION := 1
const RUTA := "user://partida.json"
const MENU_PRINCIPAL := "res://interfaz/menu_principal.tscn"

## Las herramientas usan un archivo temporal y desactivan el guardado automático.
var ruta := RUTA
var automatico := true
var ultimo_mensaje := "Todavía no hay una partida guardada."
var fecha := ""

var _datos: Dictionary = {}
var _restaurando := false
var _pendiente := false
var _bloqueado := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var argumentos := OS.get_cmdline_args()
	automatico = not ("--script" in argumentos or "-s" in argumentos or "--sin-guardado" in OS.get_cmdline_user_args())
	get_tree().scene_changed.connect(_al_cambiar_escena)
	Encargos.cambiado.connect(_programar_guardado)
	if not automatico:
		return
	get_tree().auto_accept_quit = false
	_cargar_al_abrir.call_deferred()


func _cargar_al_abrir() -> void:
	# Una escena abierta directamente desde el editor conserva su carga automática.
	var escena := _escena_jugable()
	if escena == null or not hay_partida():
		return
	# Deja que el suelo y los habitantes terminen de entrar antes de reconstruirla.
	for i in 3:
		await get_tree().physics_frame
	if is_instance_valid(escena) and escena == _escena_jugable():
		cargar()


## Guarda también el avance parcial. Los sistemas deciden qué datos son persistentes.
func guardar() -> bool:
	var escena := _escena_jugable()
	if escena == null or _restaurando:
		return false
	var escenarios: Dictionary = _datos.get("escenarios", {}).duplicate(true)
	var nodos: Dictionary = {}
	for nodo in get_tree().get_nodes_in_group(&"persistentes"):
		if escena.is_ancestor_of(nodo):
			nodos[String(escena.get_path_to(nodo))] = nodo.a_diccionario()
	escenarios[escena.scene_file_path] = nodos
	var ahora := Time.get_datetime_string_from_system(false, true)
	var nuevos := {"version": VERSION, "fecha": ahora, "escenarios": escenarios,
		"sistemas": {"encargos": Encargos.a_diccionario(), "fauna_anomala": FaunaAnomala.a_diccionario()}}
	var archivo := FileAccess.open(ruta + ".tmp", FileAccess.WRITE)
	if archivo == null:
		return _informar(false, "No se pudo abrir el archivo de guardado.")
	archivo.store_string(JSON.stringify(nuevos, "\t"))
	archivo.flush()
	var error := archivo.get_error()
	archivo.close()
	if error != OK:
		return _informar(false, "No se pudo terminar de escribir la partida.")
	# Conserva una copia válida para recuperarse de un archivo dañado.
	if not _leer(ruta).is_empty():
		if DirAccess.copy_absolute(ruta, ruta + ".bak") != OK:
			return _informar(false, "No se pudo respaldar la partida anterior.")
	if DirAccess.rename_absolute(ruta + ".tmp", ruta) != OK:
		return _informar(false, "No se pudo reemplazar la partida anterior.")
	_datos = nuevos
	fecha = ahora
	_bloqueado = false
	return _informar(true, "Partida guardada.")


## Comprueba la versión; en el menú inicial, el mundo se abre después de cargar.
func cargar() -> bool:
	var datos := _leer(ruta)
	var recuperada := false
	if datos.is_empty():
		datos = _leer(ruta + ".bak")
		recuperada = not datos.is_empty()
	if datos.is_empty():
		_bloqueado = hay_partida()
		return _informar(false, "No se pudo cargar la partida: archivo dañado o versión incompatible.")
	_restaurando = true
	_pendiente = false
	_datos = datos
	var sistemas: Dictionary = datos["sistemas"]
	Encargos.desde_diccionario(sistemas["encargos"])
	FaunaAnomala.desde_diccionario(sistemas["fauna_anomala"])
	# Recargar reconstruye también defensas, rivales y presencias desde el progreso.
	if _escena_jugable() != null:
		get_tree().reload_current_scene()
	fecha = str(datos.get("fecha", ""))
	_bloqueado = recuperada
	_restaurando = false
	return _informar(true, "Se recuperó la copia de seguridad. Guardá para confirmarla." if recuperada else "Partida cargada.")


func hay_partida() -> bool:
	return FileAccess.file_exists(ruta) or FileAccess.file_exists(ruta + ".bak")


func _escena_jugable() -> Node:
	var escena := get_tree().current_scene
	if escena != null and escena.scene_file_path != MENU_PRINCIPAL:
		return escena
	return null


## Borra los archivos y reinicia el progreso; la interfaz vuelve a abrir la escena.
func borrar() -> bool:
	for archivo in [ruta, ruta + ".bak", ruta + ".tmp"]:
		if FileAccess.file_exists(archivo) and DirAccess.remove_absolute(archivo) != OK:
			return _informar(false, "No se pudo borrar la partida.")
	_restaurando = true
	Encargos.desde_diccionario({})
	FaunaAnomala.desde_diccionario({})
	_datos.clear()
	fecha = ""
	_pendiente = false
	_bloqueado = false
	_restaurando = false
	return _informar(true, "Partida borrada. Empezás de nuevo.")


func _leer(archivo: String) -> Dictionary:
	if not FileAccess.file_exists(archivo):
		return {}
	var lector := FileAccess.open(archivo, FileAccess.READ)
	if lector == null:
		return {}
	var json := JSON.new()
	if json.parse(lector.get_as_text()) != OK or not json.data is Dictionary:
		return {}
	var datos: Dictionary = json.data
	if datos.get("version") != VERSION or not datos.get("escenarios") is Dictionary:
		return {}
	var sistemas: Variant = datos.get("sistemas")
	if not sistemas is Dictionary or not sistemas.get("encargos") is Dictionary or not sistemas.get("fauna_anomala") is Dictionary:
		return {}
	# Cada nodo recibe únicamente su diccionario de datos.
	for registros: Variant in datos["escenarios"].values():
		if not registros is Dictionary:
			return {}
		for registro: Variant in registros.values():
			if not registro is Dictionary:
				return {}
	return datos


func _aplicar_escena() -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var escenarios: Dictionary = _datos.get("escenarios", {})
	var nodos: Dictionary = escenarios.get(escena.scene_file_path, {})
	for nodo in get_tree().get_nodes_in_group(&"persistentes"):
		var clave := String(escena.get_path_to(nodo))
		if escena.is_ancestor_of(nodo) and nodos.has(clave):
			nodo.desde_diccionario(nodos[clave])


func _al_cambiar_escena() -> void:
	_restaurando = true
	_aplicar_escena()
	_restaurando = false


func _programar_guardado() -> void:
	if not automatico or _restaurando or _bloqueado or _pendiente:
		return
	_pendiente = true
	_guardar_pendiente.call_deferred()


func _guardar_pendiente() -> void:
	if not _pendiente:
		return
	_pendiente = false
	if automatico and not _restaurando and not _bloqueado:
		guardar()


func _notification(aviso: int) -> void:
	if not automatico:
		return
	if aviso == NOTIFICATION_WM_CLOSE_REQUEST:
		if not _bloqueado and _escena_jugable() != null:
			if not guardar():
				return
		get_tree().quit()
	elif aviso == NOTIFICATION_APPLICATION_PAUSED and not _bloqueado:
		guardar()


func _informar(correcto: bool, mensaje: String) -> bool:
	ultimo_mensaje = mensaje
	cambiado.emit()
	resultado.emit(correcto, mensaje)
	return correcto
