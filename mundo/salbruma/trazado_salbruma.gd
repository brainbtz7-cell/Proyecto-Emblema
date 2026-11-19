class_name TrazadoSalbruma
extends RefCounted
## Trazado de trabajo del recorte de Salbruma. X crece hacia el este, Z hacia el sur.
## Las coordenadas están en metros y se usan para el relieve, los senderos y el plano.

const LLEGADA := Vector2(-137.0, 25.0)
const BAJIOS := Vector2(-29.0, 24.65)
const PUERTO := Vector2(74.0, 29.0)
const CALETA := Vector2(95.0, -57.0)
const MARISMAS := Vector2(-58.0, -88.0)
const PUENTE_MARISMAS_SUR := Vector2(-55.0, -77.0)
const PUENTE_MARISMAS_NORTE := Vector2(-61.0, -99.0)
const EMBOSCADA := Vector2(0.0, -48.0)
const RESCATE := Vector2(76.0, -88.0)
const ULTIMA_MAREA := Vector2(89.0, 12.5)

const CAMINO: Array[Vector2] = [
	Vector2(-147, 27), LLEGADA, Vector2(-123, 24), Vector2(-108, 26),
	Vector2(-89, 34), Vector2(-70, 37), Vector2(-54, 34), Vector2(-41, 30),
	BAJIOS, Vector2(-16, 20), Vector2(0, 20), Vector2(16, 24),
	Vector2(34, 31), Vector2(54, 34), PUERTO, Vector2(89, 27),
]

const RIBERA: Array[Vector2] = [
	PUERTO, Vector2(76, 16), Vector2(78, 4), Vector2(83, -8),
	Vector2(89, -20), Vector2(94, -33), Vector2(92, -46), CALETA,
	Vector2(100, -64),
]

const HACIA_MARISMAS: Array[Vector2] = [
	Vector2(54, 34), Vector2(46, 26), Vector2(41, 13), Vector2(34, 4),
	Vector2(23, -3), Vector2(15, -13), Vector2(3, -27),
	Vector2(-14, -38), Vector2(-30, -50), Vector2(-40, -62), Vector2(-49, -71),
	PUENTE_MARISMAS_SUR, MARISMAS, PUENTE_MARISMAS_NORTE,
	Vector2(-55, -107), Vector2(-45, -114), Vector2(-33, -123),
]

const ARROYO: Array[Vector2] = [
	Vector2(-77, -31), Vector2(-62, -19), Vector2(-51, -4), Vector2(-43, 11),
	Vector2(-36, 21), Vector2(-29, 23), Vector2(-19, 18), Vector2(-8, 10),
	Vector2(9, 8), Vector2(25, 4), Vector2(43, -7), Vector2(62, -15),
	Vector2(83, -24), Vector2(110, -23), Vector2(127, -23),
]

const INVESTIGACION: Array[Vector2] = [
	Vector2(3, -27), Vector2(5, -36), Vector2(3, -44), EMBOSCADA,
]

const HACIA_RESCATE: Array[Vector2] = [
	CALETA, Vector2(89, -64), Vector2(81, -72), Vector2(76, -79), Vector2(76, -86.5),
]


static func x_del_rio(z: float) -> float:
	# El cauce se acerca al centro de Salbruma al norte, se abre junto a
	# la caleta y vuelve hacia la ribera occidental al llegar al puerto.
	return 119.0 + 11.0 * sin((z + 66.0) * 0.038) - 9.0 * sin((z + 18.0) * 0.076)


static func peso_de_marisma(punto: Vector2) -> float:
	var valle := ((punto - MARISMAS) / Vector2(65.0, 56.0)).length()
	var entrada := ((punto - Vector2(-48, -69)) / Vector2(21.0, 24.0)).length()
	return maxf(1.0 - smoothstep(0.37, 1.0, valle), 0.87 * (1.0 - smoothstep(0.24, 1.0, entrada)))


static func distancia_a_camino(punto: Vector2) -> float:
	var caminos_principales := minf(
		distancia_a_tramo(punto, CAMINO),
		minf(distancia_a_tramo(punto, RIBERA), distancia_a_tramo(punto, HACIA_MARISMAS))
	)
	return minf(caminos_principales, minf(distancia_a_tramo(punto, INVESTIGACION), distancia_a_tramo(punto, HACIA_RESCATE)))


static func distancia_a_tramo(punto: Vector2, tramo: Array[Vector2]) -> float:
	var distancia := INF
	for indice in range(1, tramo.size()):
		var cerca := Geometry2D.get_closest_point_to_segment(punto, tramo[indice - 1], tramo[indice])
		distancia = minf(distancia, cerca.distance_squared_to(punto))
	return sqrt(distancia)
