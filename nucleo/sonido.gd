class_name Sonido
extends Object
## Reproduce los efectos de sonido y el ambiente, sin autoload.
##
## Uso: Sonido.efecto(&"salto"), Sonido.efecto_en(&"paso_pasto", posicion),
## Sonido.iniciar_ambiente(arbol). Los archivos están en sonido/ y son
## provisionales: se generan con herramientas/generar_sonidos.py.

const CARPETA := "res://sonido/"
## Cuántos sonidos pueden sonar a la vez.
const VOCES := 12
## Algunos efectos tienen variantes numeradas (paso_pasto_1, _2, _3).
const VARIANTES := {&"paso_pasto": 3, &"paso_arena": 3, &"paso_roca": 3, &"paso_agua": 3}

## Volumen general de los efectos, en decibeles.
static var volumen_efectos := -4.0
## Volumen del ambiente, en decibeles.
static var volumen_ambiente := -14.0
## Apaga todo el sonido (por ejemplo, en las pruebas automáticas).
static var silencio := false

static var _cache: Dictionary[String, AudioStream] = {}
static var _voces: Array[AudioStreamPlayer3D] = []
static var _voces_planas: Array[AudioStreamPlayer] = []
static var _siguiente := 0
static var _ambiente: Array[AudioStreamPlayer] = []


## Efecto que se oye igual en todas partes (interfaz, el propio protagonista).
static func efecto(nombre: StringName, variacion_de_tono := 0.08) -> void:
	var corriente := _cargar(nombre)
	if corriente == null or silencio:
		return
	var arbol := Engine.get_main_loop() as SceneTree
	if _voces_planas.size() < VOCES / 2:
		var nueva := AudioStreamPlayer.new()
		arbol.root.add_child.call_deferred(nueva)
		_voces_planas.append(nueva)
	var voz := _voces_planas[_siguiente % _voces_planas.size()]
	_siguiente += 1
	voz.stream = corriente
	voz.volume_db = volumen_efectos
	voz.pitch_scale = 1.0 + randf_range(-variacion_de_tono, variacion_de_tono)
	if voz.is_inside_tree():
		voz.play()
	else:
		voz.play.call_deferred()


## Efecto ubicado en el mundo: suena más bajo cuanto más lejos está.
static func efecto_en(nombre: StringName, posicion: Vector3, variacion_de_tono := 0.1) -> void:
	var corriente := _cargar(nombre)
	if corriente == null or silencio:
		return
	var arbol := Engine.get_main_loop() as SceneTree
	if _voces.size() < VOCES:
		var nueva := AudioStreamPlayer3D.new()
		nueva.unit_size = 6.0
		nueva.max_distance = 40.0
		arbol.root.add_child(nueva)
		_voces.append(nueva)
	var voz := _voces[_siguiente % _voces.size()]
	_siguiente += 1
	voz.stream = corriente
	voz.global_position = posicion
	voz.volume_db = volumen_efectos
	voz.pitch_scale = 1.0 + randf_range(-variacion_de_tono, variacion_de_tono)
	voz.play()


## Arranca los sonidos de fondo (olas y viento). Llamarlo más de una vez no los duplica.
static func iniciar_ambiente(arbol: SceneTree) -> void:
	if silencio or not _ambiente.is_empty():
		return
	for nombre in [&"ambiente_olas", &"ambiente_viento"]:
		var corriente := _cargar(nombre) as AudioStreamWAV
		if corriente == null:
			continue
		corriente = corriente.duplicate()
		corriente.loop_mode = AudioStreamWAV.LOOP_FORWARD
		corriente.loop_begin = 0
		corriente.loop_end = corriente.data.size() / 2
		var reproductor := AudioStreamPlayer.new()
		reproductor.stream = corriente
		reproductor.volume_db = volumen_ambiente
		reproductor.autoplay = true
		arbol.root.add_child.call_deferred(reproductor)
		_ambiente.append(reproductor)


static func _cargar(nombre: StringName) -> AudioStream:
	var archivo := String(nombre)
	if VARIANTES.has(nombre):
		archivo += "_%d" % randi_range(1, VARIANTES[nombre])
	if not _cache.has(archivo):
		var ruta := CARPETA + archivo + ".wav"
		_cache[archivo] = load(ruta) if ResourceLoader.exists(ruta) else null
	return _cache[archivo]
