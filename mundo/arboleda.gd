@tool
class_name Arboleda
extends Node3D
## Reparte árboles sobre el terreno, en manchones, siguiendo unas pocas reglas.
##
## Los árboles se crean al cargar la escena y no se guardan dentro de ella:
## se vuelven a repartir solos si cambia el terreno. También se ven en el
## editor. Para poner un árbol a mano, arrastrar su escena al nivel (fuera
## de este nodo, que borra a sus hijos cada vez que reparte).

## Terreno sobre el que se plantan.
@export var terreno: Terreno
## Escenas de árbol entre las que elige al azar.
@export var arboles: Array[PackedScene] = []

## Cada semilla da otro reparto.
@export var semilla := 5:
	set(valor):
		semilla = valor
		_repartir_si_listo()

## Cuántos árboles intenta plantar.
@export var cantidad := 70:
	set(valor):
		cantidad = valor
		_repartir_si_listo()

## Distancia mínima entre un árbol y otro, en metros.
@export var separacion := 2.8:
	set(valor):
		separacion = valor
		_repartir_si_listo()

@export_tool_button("Repartir de nuevo", "Reload") var _boton_repartir := repartir

@export_group("Dónde crecen")
## Radio de reparto alrededor de este nodo. En cero usa todo el terreno.
@export var extension_de_reparto := Vector2.ZERO
## Solo crecen donde el suelo esté entre estas dos alturas, en metros.
@export var altura_minima := 1.3
@export var altura_maxima := 8.0
## Pendiente máxima del suelo (1.0 = 45 grados).
@export var pendiente_maxima := 0.55
## 0 = repartidos por todas partes; 1 = solo en manchones apretados.
@export_range(0.0, 1.0) var agrupamiento := 0.5
## Tamaño aproximado de cada manchón, en metros.
@export var tamano_de_los_manchones := 22.0

@export_group("Variación")
@export var escala_minima := 0.8
@export var escala_maxima := 1.35
## Tintes de follaje entre los que elige cada árbol.
@export var tintes: Array[Color] = [
	Color(1.0, 1.0, 1.0),
	Color(0.88, 0.96, 0.8),
	Color(1.0, 0.94, 0.76),
	Color(0.84, 0.94, 0.92),
]

@export_group("Claros")
## Alrededor de estos nodos no se planta nada.
@export var dejar_libre: Array[Node3D] = []
## Radio del claro, en metros.
@export var radio_libre := 5.0


func _ready() -> void:
	if terreno:
		terreno.generado.connect(repartir)
	repartir()


## Borra los árboles que haya y los vuelve a plantar.
func repartir() -> void:
	for hijo in get_children():
		remove_child(hijo)
		hijo.queue_free()
	if terreno == null or arboles.is_empty():
		return

	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var manchones := FastNoiseLite.new()
	manchones.seed = semilla
	manchones.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	manchones.frequency = 1.0 / tamano_de_los_manchones

	var centro := terreno.global_position
	var mitad := terreno.tamano * 0.5
	var extension := Vector2.ONE * mitad
	if extension_de_reparto != Vector2.ZERO:
		centro = global_position
		extension = extension_de_reparto
	var plantados: Array[Vector2] = []
	# Prueba lugares al azar y se queda con los que cumplen todas las reglas.
	for intento in cantidad * 60:
		if plantados.size() >= cantidad:
			break
		var lugar := Vector2(centro.x + azar.randf_range(-extension.x, extension.x), centro.z + azar.randf_range(-extension.y, extension.y))
		if _sirve(lugar, manchones, azar, plantados):
			plantados.append(lugar)
			_plantar(lugar, azar)


func _repartir_si_listo() -> void:
	if is_node_ready():
		repartir()


func _sirve(lugar: Vector2, manchones: FastNoiseLite, azar: RandomNumberGenerator, plantados: Array[Vector2]) -> bool:
	var altura := terreno.altura_en(lugar.x, lugar.y)
	if altura < altura_minima or altura > altura_maxima or not terreno.admite_vegetacion(lugar):
		return false

	var desnivel := Vector2(
		terreno.altura_en(lugar.x + 1.0, lugar.y) - terreno.altura_en(lugar.x - 1.0, lugar.y),
		terreno.altura_en(lugar.x, lugar.y + 1.0) - terreno.altura_en(lugar.x, lugar.y - 1.0))
	if desnivel.length() / 2.0 > pendiente_maxima:
		return false

	# El ruido marca dónde hay manchón; fuera de ellos casi no crece nada.
	var espesura := manchones.get_noise_2d(lugar.x, lugar.y) * 0.5 + 0.5
	var umbral := agrupamiento * 0.6
	if azar.randf() > smoothstep(umbral, umbral + 0.2, espesura):
		return false

	for nodo in dejar_libre:
		if nodo and lugar.distance_to(Vector2(nodo.global_position.x, nodo.global_position.z)) < radio_libre:
			return false
	for otro in plantados:
		if lugar.distance_to(otro) < separacion:
			return false
	return true


func _plantar(lugar: Vector2, azar: RandomNumberGenerator) -> void:
	var arbol := arboles[azar.randi() % arboles.size()].instantiate() as Node3D
	# Se hunde apenas para que el tronco no quede en el aire en las laderas.
	arbol.position = to_local(Vector3(lugar.x, terreno.altura_en(lugar.x, lugar.y) - 0.15, lugar.y))
	arbol.rotation.y = azar.randf() * TAU
	add_child(arbol)

	# Se agranda solo la parte visible: los cuerpos de física no llevan bien la escala.
	var modelo := arbol.get_node_or_null("Modelo") as Node3D
	if modelo:
		modelo.scale = Vector3.ONE * azar.randf_range(escala_minima, escala_maxima)
	var copa := arbol.get_node_or_null("Modelo/Copa")
	if copa and not tintes.is_empty():
		var tinte := tintes[azar.randi() % tintes.size()]
		for hojas in copa.get_children():
			if hojas is GeometryInstance3D:
				hojas.set_instance_shader_parameter(&"tinte", tinte)
