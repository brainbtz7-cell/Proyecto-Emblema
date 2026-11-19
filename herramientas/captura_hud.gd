extends SceneTree
## Captura de muestra del HUD en Puerto Albor: seguimiento, cartel del lugar,
## aviso de interacción y atajos. Sirve para revisar el estilo a ojo.
## Uso (con ventana): godot --path . -s herramientas/captura_hud.gd -- <carpeta> [ancho alto]
## Con 2560 1440 la interfaz se dibuja a escala 2, como en una pantalla Retina.

const ESCENA := "res://mundo/salbruma/salbruma.tscn"
const DUDAS := preload("res://encargos/puerto_albor_dudas_razonables.tres")

var _salida := ""


func _initialize() -> void:
	_correr.call_deferred()


func _correr() -> void:
	var argumentos := OS.get_cmdline_user_args()
	if argumentos.is_empty() or DisplayServer.get_name() == "headless":
		print("Uso: con ventana y -- <carpeta> [ancho alto]")
		quit(1)
		return
	_salida = argumentos[0]
	DirAccess.make_dir_recursive_absolute(_salida)
	var tamano := Vector2i(1280, 720)
	if argumentos.size() >= 3:
		tamano = Vector2i(int(argumentos[1]), int(argumentos[2]))
	root.mode = Window.MODE_WINDOWED
	root.size = tamano
	# Arriba de todo para que macOS no deje de dibujarla, sin tomar foco ni ratón.
	root.always_on_top = true
	root.unfocusable = true
	root.mouse_passthrough = true
	_preparar_encargos()
	change_scene_to_file(ESCENA)
	await scene_changed
	for i in 30:
		await physics_frame
	var jugador: Node3D = current_scene.get_node("Jugador")
	var terreno: Node = current_scene.get_node("Terreno")
	# Frente al barquero, mirando al pueblo: aparece "Investigar al profeta".
	var barquero: Node3D = current_scene.get_node("Barquero")
	var punto := barquero.global_position + Vector3(-1.5, 0, 0.4)
	punto.y = terreno.altura_en(punto.x, punto.z) + 0.15
	jugador.teletransportar(punto)
	# La cámara mira hacia el pueblo, por detrás del protagonista.
	jugador.get_node("Camara").rotation.y = deg_to_rad(-60)
	for i in 40:
		await physics_frame
	await create_timer(0.5).timeout
	await _foto("hud_%dx%d" % [tamano.x, tamano.y])
	print("Captura HUD lista en ", _salida)
	quit()


# Junco y la primera tanda entregados; Dudas razonables con una consulta hecha.
func _preparar_encargos() -> void:
	var registros: Array[Dictionary] = []
	for archivo in DirAccess.get_files_at("res://encargos"):
		if archivo.ends_with(".tres") and (archivo.begins_with("puerto_junco_") or archivo in ["puerto_albor_gruta_olvidada.tres", "puerto_albor_arena.tres", "puerto_albor_caparazones.tres"]):
			var encargo: Encargo = load("res://encargos/" + archivo)
			registros.append({"id": String(encargo.id), "estado": 3, "avance": encargo.cantidad, "elementos": []})
	registros.append({"id": "la_voz_desenmascara_al_impostor", "estado": 1, "avance": 0, "elementos": []})
	registros.append({"id": String(DUDAS.id), "estado": 1, "avance": 1, "elementos": ["habitante_0"]})
	root.get_node("Encargos").desde_diccionario({"encargos": registros})


func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var ruta := _salida.path_join(nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
