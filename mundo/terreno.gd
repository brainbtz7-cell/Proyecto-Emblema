@tool
class_name Terreno
extends StaticBody3D
## Terreno de prueba: una isla rodeada de bajíos, generada a partir de ruido.
##
## Crea la malla visible, la colisión y un mapa de altura que los shaders del
## suelo y del agua usan para pintarse. También se ve dentro del editor.
## Cambiar la semilla da otra isla.

## Se emite cada vez que se vuelve a crear el relieve.
signal generado

## Cada semilla produce un relieve distinto.
@export var semilla := 3:
	set(valor):
		semilla = valor
		_regenerar()

## Lado del terreno, en metros.
@export var tamano := 128.0:
	set(valor):
		tamano = valor
		_regenerar()

## Cantidad de celdas por lado. Más celdas dan más detalle.
@export_range(8, 256) var celdas := 96:
	set(valor):
		celdas = valor
		_regenerar()

## Altura aproximada de las colinas, en metros sobre el agua.
@export var altura_maxima := 9.0:
	set(valor):
		altura_maxima = valor
		_regenerar()

## Profundidad aproximada del mar alrededor, en metros.
@export var profundidad_maxima := 6.0:
	set(valor):
		profundidad_maxima = valor
		_regenerar()

## Material con el que se pinta el suelo.
@export var material: Material:
	set(valor):
		material = valor
		if _malla:
			_malla.material_override = material

var _alturas := PackedFloat32Array()
var _puntos := 0
var _paso := 1.0
var _malla: MeshInstance3D
var _colision: CollisionShape3D
var _textura_de_altura: ImageTexture


func _ready() -> void:
	# Nodos internos: se ven y colisionan, pero no se guardan dentro de la escena.
	_malla = MeshInstance3D.new()
	add_child(_malla, false, Node.INTERNAL_MODE_BACK)
	_colision = CollisionShape3D.new()
	add_child(_colision, false, Node.INTERNAL_MODE_BACK)
	generar()


## Altura del suelo, en metros, en un punto del mundo.
func altura_en(x: float, z: float) -> float:
	var mitad := tamano * 0.5
	var u := clampf((x - global_position.x + mitad) / _paso, 0.0, _puntos - 1.001)
	var v := clampf((z - global_position.z + mitad) / _paso, 0.0, _puntos - 1.001)
	var i := int(u)
	var j := int(v)
	var cerca := lerpf(_altura(i, j), _altura(i + 1, j), u - i)
	var lejos := lerpf(_altura(i, j + 1), _altura(i + 1, j + 1), u - i)
	return global_position.y + lerpf(cerca, lejos, v - j)


## Permite reservar caminos u otros espacios de un escenario.
func admite_vegetacion(_lugar: Vector2) -> bool:
	return true


## Vuelve a crear el relieve, la malla y la colisión.
func generar() -> void:
	var ruido := FastNoiseLite.new()
	ruido.seed = semilla
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.frequency = 0.02
	ruido.fractal_type = FastNoiseLite.FRACTAL_FBM
	ruido.fractal_octaves = 4

	_puntos = celdas + 1
	_paso = tamano / celdas
	var mitad := tamano * 0.5
	_alturas.resize(_puntos * _puntos)
	for j in _puntos:
		for i in _puntos:
			_alturas[j * _puntos + i] = _calcular_altura(ruido, i * _paso - mitad, j * _paso - mitad)

	_construir_malla()
	_publicar_mapa_de_altura()
	generado.emit()


func _regenerar() -> void:
	if is_node_ready():
		generar()


func _altura(i: int, j: int) -> float:
	return _alturas[j * _puntos + i]


# Forma del relieve: una isla alta en el centro, un anillo de bajíos con bancos
# de arena alrededor y mar profundo en el borde.
# Cerca del nivel del agua el relieve se aplana para dejar playas y bajíos anchos.
func _calcular_altura(ruido: FastNoiseLite, x: float, z: float) -> float:
	var lejania := Vector2(x, z).length() / (tamano * 0.5)
	var nivel := 0.85 - smoothstep(0.0, 0.75, lejania) * 1.05
	nivel += ruido.get_noise_2d(x, z) * 0.6
	nivel -= smoothstep(0.78, 1.0, lejania) * 1.2
	if nivel > 0.0:
		return pow(nivel, 1.5) * altura_maxima
	return -pow(-nivel, 1.3) * profundidad_maxima


func _punto(i: int, j: int) -> Vector3:
	var mitad := tamano * 0.5
	return Vector3(i * _paso - mitad, _altura(i, j), j * _paso - mitad)


# Cada triángulo lleva sus propios vértices y una sola normal: eso da el
# aspecto facetado, de pocos polígonos.
func _construir_malla() -> void:
	var vertices := PackedVector3Array()
	var normales := PackedVector3Array()
	vertices.resize(celdas * celdas * 6)
	normales.resize(celdas * celdas * 6)
	var k := 0
	for j in celdas:
		for i in celdas:
			var a := _punto(i, j)
			var b := _punto(i + 1, j)
			var c := _punto(i, j + 1)
			var d := _punto(i + 1, j + 1)
			# La diagonal se alterna para que el relieve no quede "peinado" hacia un lado.
			if (i + j) % 2 == 0:
				k = _agregar_triangulo(vertices, normales, k, a, b, c)
				k = _agregar_triangulo(vertices, normales, k, b, d, c)
			else:
				k = _agregar_triangulo(vertices, normales, k, a, b, d)
				k = _agregar_triangulo(vertices, normales, k, a, d, c)

	var datos := []
	datos.resize(Mesh.ARRAY_MAX)
	datos[Mesh.ARRAY_VERTEX] = vertices
	datos[Mesh.ARRAY_NORMAL] = normales
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)
	_malla.mesh = malla
	_malla.material_override = material

	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(vertices)
	_colision.shape = forma


# Escribe un triángulo a partir de la posición k y devuelve la posición siguiente.
func _agregar_triangulo(vertices: PackedVector3Array, normales: PackedVector3Array, k: int, p: Vector3, q: Vector3, r: Vector3) -> int:
	var normal := (r - p).cross(q - p).normalized()
	vertices[k] = p
	vertices[k + 1] = q
	vertices[k + 2] = r
	normales[k] = normal
	normales[k + 1] = normal
	normales[k + 2] = normal
	return k + 3


# Guarda las alturas en una imagen y la comparte con todos los shaders
# (ver shaders/datos_terreno.gdshaderinc).
func _publicar_mapa_de_altura() -> void:
	var alturas_del_mundo := _alturas.duplicate()
	if not is_zero_approx(global_position.y):
		for n in alturas_del_mundo.size():
			alturas_del_mundo[n] += global_position.y
	var imagen := Image.create_from_data(_puntos, _puntos, false, Image.FORMAT_RF, alturas_del_mundo.to_byte_array())
	_textura_de_altura = ImageTexture.create_from_image(imagen)
	var esquina := Vector2(global_position.x, global_position.z) - Vector2.ONE * tamano * 0.5
	RenderingServer.global_shader_parameter_set(&"terreno_mapa_altura", _textura_de_altura.get_rid())
	RenderingServer.global_shader_parameter_set(&"terreno_origen", esquina)
	RenderingServer.global_shader_parameter_set(&"terreno_paso", _paso)
	RenderingServer.global_shader_parameter_set(&"terreno_puntos", float(_puntos))
