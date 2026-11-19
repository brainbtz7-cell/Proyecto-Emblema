@tool
class_name TerrenoSalbruma
extends Terreno
## Recorte de Salbruma con el cauce, el poblado y los humedales.

const TRAZADO := preload("res://mundo/salbruma/trazado_salbruma.gd")

var _mascara := PackedByteArray()


func generar() -> void:
	_mascara.resize((celdas + 1) * (celdas + 1))
	super.generar()
	var imagen := Image.create_from_data(celdas + 1, celdas + 1, false, Image.FORMAT_R8, _mascara)
	if material is ShaderMaterial:
		material.set_shader_parameter(&"mascara_camino", ImageTexture.create_from_image(imagen))


func admite_vegetacion(lugar: Vector2) -> bool:
	var punto := lugar - Vector2(global_position.x, global_position.z)
	return TRAZADO.distancia_a_camino(punto) > 4.7


## La misma cobertura que usa el suelo para pintar los senderos.
func cobertura_de_camino(lugar: Vector2) -> float:
	var punto := lugar - Vector2(global_position.x, global_position.z)
	var celda := ((punto / tamano + Vector2.ONE * 0.5) * float(celdas)).clamp(Vector2.ZERO, Vector2.ONE * (float(celdas) - 0.001))
	var i := int(celda.x)
	var j := int(celda.y)
	var fila := j * (celdas + 1) + i
	var siguiente := fila + celdas + 1
	var cerca := lerpf(_mascara[fila], _mascara[fila + 1], celda.x - i)
	var lejos := lerpf(_mascara[siguiente], _mascara[siguiente + 1], celda.x - i)
	return lerpf(cerca, lejos, celda.y - j) / 255.0


func _calcular_altura(ruido: FastNoiseLite, x: float, z: float) -> float:
	var punto := Vector2(x, z)
	var detalle := ruido.get_noise_2d(x, z)
	var distancia_camino := TRAZADO.distancia_a_camino(punto)
	var traza := 1.0 - smoothstep(1.25, 3.1, distancia_camino)
	traza = maxf(traza, _zona(punto, TRAZADO.PUERTO, Vector2(9.8, 5.0)) * 0.74)
	traza = maxf(traza, _zona(punto, TRAZADO.PUERTO_ALBOR, Vector2(8.5, 4.5)) * 0.74)
	_guardar_traza(punto, traza)

	var altura := 2.2 + detalle * lerpf(1.35, 0.46, traza)
	altura += 16.0 * _loma(punto, Vector2(-122, -24), Vector2(46, 36))
	altura += 10.5 * _loma(punto, Vector2(-100, 74), Vector2(50, 24))
	altura += 12.0 * _loma(punto, Vector2(-6, 83), Vector2(76, 35))
	altura += 21.0 * _loma(punto, Vector2(-80, -103), Vector2(75, 55))
	altura += 28.0 * _loma(punto, Vector2(-139, -146), Vector2(33, 52))
	altura += 27.0 * _loma(punto, Vector2(-20, -141), Vector2(53, 35))
	altura += 13.0 * _loma(punto, Vector2(178, -37), Vector2(28, 73))
	altura += 18.0 * _loma(punto, Vector2(174, 104), Vector2(24, 49))

	var llano := _zona(punto, TRAZADO.PUERTO, Vector2(29, 20))
	altura = lerpf(altura, 1.66 + detalle * 0.17, llano)
	var caleta := _zona(punto, TRAZADO.CALETA, Vector2(22, 20))
	altura = lerpf(altura, 1.13 + detalle * 0.37, caleta)
	var campamento := _zona(punto, TRAZADO.RESCATE, Vector2(11.0, 10.0))
	altura = lerpf(altura, 1.46 + detalle * 0.21, campamento)
	altura = _humedal(punto, altura, detalle)
	altura = _salida_del_humedal(punto, altura, detalle)
	altura = _paso_hacia_albor(punto, altura, detalle)
	var albor := _zona(punto, TRAZADO.PUERTO_ALBOR, Vector2(24, 18))
	altura = lerpf(altura, 2.0 + detalle * 0.17, albor)

	var eje_rio := TRAZADO.x_del_rio(z)
	var ancho_rio := 17.0 + 2.0 * sin(z * 0.06)
	if x < eje_rio:
		# Una entrada de agua corta en la orilla de Salbruma forma la caleta.
		ancho_rio += 5.7 * exp(-pow((z + 55.0) / 8.5, 2.0))
	var distancia_rio := absf(x - eje_rio) - ancho_rio
	distancia_rio += detalle * 1.3
	if distancia_rio < 0.0:
		return lerpf(-5.6, 0.0, smoothstep(-13.0, 0.0, distancia_rio))
	altura *= smoothstep(0.0, lerpf(18.0, 8.5, maxf(llano, caleta)), distancia_rio)

	var distancia_arroyo := TRAZADO.distancia_a_tramo(punto, TRAZADO.ARROYO)
	var charca := _zona(punto, Vector2(-41, 16), Vector2(14, 11))
	var bajo := lerpf(-0.19, -0.5, charca)
	altura = lerpf(bajo, altura, smoothstep(1.6 + charca * 2.7, 8.0 + charca * 4.0, distancia_arroyo))
	return altura


func _humedal(punto: Vector2, elevacion: float, detalle: float) -> float:
	var peso := TRAZADO.peso_de_marisma(punto)
	if peso <= 0.0:
		return elevacion
	var perfil := 0.98 + detalle * 0.56
	var altura := lerpf(elevacion, perfil, peso)
	var borde := punto + Vector2(detalle * 4.0, detalle * 3.2)
	var cuenco := _zona(borde, Vector2(-72, -89), Vector2(24, 13))
	cuenco = maxf(cuenco, _zona(borde, Vector2(-43, -92), Vector2(18, 13)))
	cuenco = maxf(cuenco, _zona(borde, Vector2(-67, -109), Vector2(19, 9)) * 0.93)
	cuenco = maxf(cuenco, _zona(borde, Vector2(-51, -83), Vector2(16, 7)))
	return lerpf(altura, -0.74 + detalle * 0.13, cuenco)


func _salida_del_humedal(punto: Vector2, altura: float, detalle: float) -> float:
	var hacia_el_norte := -punto.y - 101.0
	if hacia_el_norte <= 0.0:
		return altura
	var cerca := Geometry2D.get_closest_point_to_segment(punto, Vector2(-55, -107), Vector2(-33, -123))
	var banda := 1.0 - smoothstep(3.5, 15.0, punto.distance_to(cerca))
	var rampa := 1.42 + hacia_el_norte * 0.27 + detalle * 0.32
	return lerpf(altura, rampa, banda * smoothstep(0.0, 7.0, hacia_el_norte))


# El sendero cruza la loma con un perfil parejo: sube y baja como mucho un
# 22 % entre la salida de las marismas y Albor. Donde la ladera es más alta
# la corta como una garganta, y donde cae de golpe la rellena.
func _paso_hacia_albor(punto: Vector2, altura: float, detalle: float) -> float:
	var medida := TRAZADO.distancia_y_avance(punto, TRAZADO.HACIA_ALBOR)
	var banda := 1.0 - smoothstep(3.0, 13.0, medida.x)
	if banda <= 0.0:
		return altura
	var largo := 0.0
	for indice in range(1, TRAZADO.HACIA_ALBOR.size()):
		largo += TRAZADO.HACIA_ALBOR[indice - 1].distance_to(TRAZADO.HACIA_ALBOR[indice])
	var subida := 7.2 + medida.y * 0.22
	# Los últimos 32 m quedan al nivel del llano de Albor.
	var bajada := 2.0 + maxf(0.0, largo - 32.0 - medida.y) * 0.22
	var tope := minf(subida, bajada) + detalle * 0.2
	return lerpf(altura, tope, banda)


func _loma(punto: Vector2, centro: Vector2, extension: Vector2) -> float:
	return exp(-((punto - centro) / extension).length_squared() * 1.65)


func _zona(punto: Vector2, centro: Vector2, extension: Vector2) -> float:
	return 1.0 - smoothstep(0.40, 1.0, ((punto - centro) / extension).length())


func _guardar_traza(punto: Vector2, peso: float) -> void:
	var celda := ((punto / tamano + Vector2.ONE * 0.5) * float(celdas)).round()
	var indice := int(celda.y) * (celdas + 1) + int(celda.x)
	_mascara[indice] = int(peso * 255.0)
