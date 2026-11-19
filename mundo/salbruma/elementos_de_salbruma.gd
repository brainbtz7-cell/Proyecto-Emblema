@tool
extends Node3D
## Construcciones y vegetación de ribera para esta versión de trabajo.

@export var terreno: Terreno

const TOON := preload("res://shaders/toon.gdshader")
const ROCA := preload("res://shaders/roca.gdshader")
const TRAZADO := preload("res://mundo/salbruma/trazado_salbruma.gd")

var _madera: Material
var _madera_clara: Material
var _madera_oscura: Material
var _piedra: Material
var _teja: Material
var _teja_oscura: Material
var _marfil: Material
var _verde: Material
var _vidrio: Material
var _cartel: Material


func _ready() -> void:
	if terreno:
		terreno.generado.connect(_construir)
		_construir()


func _construir() -> void:
	for hijo in get_children():
		remove_child(hijo)
		hijo.queue_free()
	_madera = _color(Color("785743"))
	_madera_clara = _color(Color("a37d58"))
	_madera_oscura = _color(Color("4f443c"))
	_piedra = ShaderMaterial.new()
	_piedra.shader = ROCA
	_teja = _color(Color("9d5542"))
	_teja_oscura = _color(Color("744a41"))
	_marfil = _color(Color("d5bd91"))
	_verde = _color(Color("82978b"))
	_vidrio = _color(Color("efa65e"))
	_cartel = _color(Color("4d4839"))

	_puerto()
	_bajios()
	_caleta()
	_marismas()
	_campamento_de_prueba()
	_sendero_de_los_faros()
	_puerto_albor()
	_cayo_de_salcristal()
	_gruta_olvidada()


func _puerto() -> void:
	_casa(Vector2(56, 23), Vector2(5.8, 4.7), 2.7, deg_to_rad(166), _verde, _teja_oscura)
	_casa(Vector2(67, 23), Vector2(7.0, 5.0), 3.4, PI, _marfil, _teja)
	_casa(Vector2(84, 21), Vector2(5.8, 4.9), 2.8, deg_to_rad(168), _marfil, _teja)
	_casa(Vector2(58, 40), Vector2(6.3, 5.1), 2.8, deg_to_rad(-8), _marfil, _teja_oscura)
	_casa(Vector2(69, 39), Vector2(7.7, 5.3), 3.3, deg_to_rad(-5), _verde, _teja)
	_casa(Vector2(80, 37), Vector2(6.4, 4.7), 2.6, deg_to_rad(14), _marfil, _teja_oscura)
	_casa(Vector2(75, 47), Vector2(5.8, 4.2), 2.5, deg_to_rad(-19), _verde, _teja)
	_casa(Vector2(91, 34), Vector2(5.2, 4.4), 2.6, deg_to_rad(-13), _verde, _teja_oscura)

	var rampa := Vector2(91.0, 27.0)
	_pasarela(_suelo(rampa, 0.07), Vector3(100.0, 1.4, 27.0), 4.1, true)
	_pasarela(Vector3(100.0, 1.4, 27.0), Vector3(112.5, 1.4, 27.0), 4.1, true)
	_pasarela(Vector3(111.0, 1.4, 18.0), Vector3(111.0, 1.4, 37.0), 2.65, false)
	_bote(Vector3(114.0, 0.25, 21.8), 0.12)
	_bote(Vector3(106.5, 0.25, 35.4), -0.16)
	_cajas(Vector3(105.8, 1.45, 25.5))
	_cajas(_suelo(Vector2(86, 28.1)))
	_red(_suelo(Vector2(93.5, 22.0)), -0.30, false)

	_cartel_en(Vector2(47, 34.8), "Puerto Junco", 0.08)
	_cartel_en(Vector2(74, 20), "Caleta", deg_to_rad(-42))
	_cartel_en(Vector2(42, 14), "Hacia las marismas", deg_to_rad(22))
	_puesto(Vector2(78.7, 24.1), deg_to_rad(175))
	_poste_con_luz(Vector2(52, 30.4))
	_poste_con_luz(Vector2(92.2, 24.6))


func _bajios() -> void:
	var laja := Vector2(-38.5, 28.5)
	var otra_orilla := Vector2(-17.5, 20)
	_pasarela(_suelo(laja, 0.10), _suelo(otra_orilla, 0.10), 2.7, true)
	_cartel_en(Vector2(-55.6, 29.4), "Bajíos de Salbruma", deg_to_rad(-54))
	_plantar_juncos(Vector2(-46, 12), 10.0, 7)
	_plantar_juncos(Vector2(-28, 23), 11.0, 28)
	_plantar_juncos(Vector2(4, 8), 15.0, 64)
	_plantar_juncos(Vector2(38, -5), 13.0, 82)

	_roca_en(Vector2(-133.4, 19.8), Vector3(3.7, 2.9, 3.1), 0.46)
	_roca_en(Vector2(-135.1, 30.1), Vector3(3.1, 1.9, 3.0), -0.77)
	_roca_en(Vector2(-87.0, 28.3), Vector3(4.4, 1.7, 3.0), -0.48)
	_roca_en(Vector2(-42.3, 26.2), Vector3(2.0, 1.0, 1.4), 0.89)
	_roca_en(Vector2(-26.5, 14.9), Vector3(2.4, 1.1, 1.9), 0.25)
	_roca_en(Vector2(-18.2, 30.5), Vector3(3.6, 2.2, 2.5), 0.54)
	_roca_en(Vector2(4.5, 16.2), Vector3(2.4, 0.95, 2.0), 0.2)


func _caleta() -> void:
	_pasarela(_suelo(Vector2(87.6, -17.2), 0.10), _suelo(Vector2(92.1, -28.0), 0.10), 2.2, true)
	_cartel_en(Vector2(89.9, -40.7), "Caleta de las Redes Rotas", deg_to_rad(16))
	_roca_en(Vector2(85.6, -56.8), Vector3(4.7, 2.7, 3.5), 0.5)
	_roca_en(Vector2(82.4, -59.4), Vector3(3.9, 1.8, 3.2), 1.4)
	_roca_en(Vector2(94.2, -65.8), Vector3(3.5, 1.2, 2.2), -0.3)
	_roca_en(Vector2(109.2, -52.6), Vector3(3.2, 1.2, 2.4), 0.65)
	_roca_en(Vector2(111.4, -50), Vector3(1.9, 0.9, 1.4), 0.16)
	_plantar_juncos(Vector2(106, -56), 10.0, 34)

	var pie := Vector2(101.7, -55.0)
	_pasarela(_suelo(pie, 0.06), Vector3(110.5, 0.68, -55.4), 1.9, false)
	_red(_suelo(Vector2(100.2, -52.9)), 0.61, true)


func _marismas() -> void:
	_cartel_en(Vector2(-55.4, -72.5), "Marismas del Caparazón", deg_to_rad(-12))
	var inicio := _suelo(TRAZADO.PUENTE_MARISMAS_SUR, 0.1)
	var fin := _suelo(TRAZADO.PUENTE_MARISMAS_NORTE, 0.1)
	_pasarela(inicio, fin, 2.9, true)
	_plantar_juncos(Vector2(-72, -88), 14.5, 191)
	_plantar_juncos(Vector2(-43, -88), 13.0, 235)
	_plantar_juncos(Vector2(-66, -107), 15.0, 324)
	_plantar_juncos(Vector2(-49, -80), 9.0, 512)
	_hojas_flotantes(Vector2(-69, -88), 11.0, 152)
	_hojas_flotantes(Vector2(-45, -90), 9.0, 717)

	_roca_en(Vector2(-63.5, -74), Vector3(5.5, 2.6, 3.4), -0.9)
	_roca_en(Vector2(-62.8, -77.2), Vector3(2.5, 1.4, 2.3), 0.4)
	_roca_en(Vector2(-81, -79.8), Vector3(2.8, 1.5, 2.2), 0.55)
	_roca_en(Vector2(-52.0, -101), Vector3(4.2, 2.0, 2.5), 0.34)
	_roca_en(Vector2(-34.2, -102), Vector3(2.45, 1.75, 2.4), 1.3)


func _campamento_de_prueba() -> void:
	_puesto(Vector2(76, -88.35), 0)
	_cajas(_suelo(Vector2(80.3, -86.4)))
	_red(_suelo(Vector2(80.8, -90.1)), deg_to_rad(12), true)
	var cerco := _soporte(_suelo(Vector2(73.2, -89.1)), deg_to_rad(76))
	for i in 7:
		var x := float(i - 3) * 0.46
		var alto := 1.04 + float(i % 3) * 0.075
		_bloque(cerco, Vector3(x, alto * 0.43, 0), Vector3(0.19, alto, 0.16), _madera_oscura)
	_bloque(cerco, Vector3(0, 0.67, 0.13), Vector3(3.07, 0.14, 0.11), _madera)
	_roca_en(Vector2(1.1, -48.4), Vector3(3.26, 1.42, 1.62), -0.37)
	_roca_en(Vector2(6.7, -48.2), Vector3(2.7, 1.55, 2.32), 0.24)


# PROVISIONAL: el documento nombra el Sendero de los Faros pero no describe
# los faros; son torres de piedra genéricas.
func _sendero_de_los_faros() -> void:
	_cartel_en(Vector2(-30.0, -118.5), "Hacia Puerto Albor", deg_to_rad(-20))
	_cartel_en(Vector2(27.5, -131.0), "Sendero de los Faros", deg_to_rad(-28))
	_faro(Vector2(31.0, -147.5), 6.2)
	_faro(Vector2(45.5, -133.5), 5.0)
	_roca_en(Vector2(40.0, -150.0), Vector3(3.4, 1.6, 2.6), 0.7)
	_roca_en(Vector2(20.5, -126.0), Vector3(2.6, 1.3, 2.0), -0.4)


func _faro(punto: Vector2, alto: float) -> void:
	var faro := _soporte(_suelo(punto, 0.1))
	var cuerpo := CylinderMesh.new()
	cuerpo.top_radius = 0.75
	cuerpo.bottom_radius = 1.15
	cuerpo.height = alto
	cuerpo.radial_segments = 8
	cuerpo.rings = 1
	_mostrar(faro, cuerpo, Vector3(0, alto * 0.5, 0), _piedra)
	_colision(faro, Vector3(0, alto * 0.5, 0), Vector3(1.8, alto, 1.8))
	_bloque(faro, Vector3(0, alto + 0.1, 0), Vector3(1.9, 0.2, 1.9), _madera_oscura)
	_bloque(faro, Vector3(0, alto + 0.55, 0), Vector3(0.9, 0.7, 0.9), _vidrio)
	_bloque(faro, Vector3(0, alto + 1.05, 0), Vector3(1.3, 0.3, 1.3), _teja_oscura)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffc777")
	luz.light_energy = 1.4
	luz.omni_range = 9.0
	faro.add_child(luz)
	luz.position = Vector3(0, alto + 0.55, 0)


# Segundo pueblo costero, río arriba. Las casas son genéricas: el documento
# dice que sus tiendas en el mapa no fijan la arquitectura definitiva.
func _puerto_albor() -> void:
	_casa(Vector2(70, -151), Vector2(6.0, 4.8), 2.8, deg_to_rad(176), _marfil, _teja)
	_casa(Vector2(80, -150), Vector2(6.8, 5.0), 3.3, deg_to_rad(184), _verde, _teja_oscura)
	_casa(Vector2(90, -151.5), Vector2(5.4, 4.4), 2.6, deg_to_rad(172), _marfil, _teja_oscura)
	_casa(Vector2(68, -170), Vector2(6.2, 4.9), 2.9, deg_to_rad(-4), _verde, _teja)
	_casa(Vector2(78.5, -171), Vector2(7.4, 5.2), 3.4, deg_to_rad(3), _marfil, _teja)
	_casa(Vector2(89, -170), Vector2(5.6, 4.5), 2.7, deg_to_rad(-9), _verde, _teja_oscura)

	var rampa := Vector2(93.0, -161.0)
	_pasarela(_suelo(rampa, 0.07), Vector3(101.0, 1.4, -161.0), 3.8, true)
	_pasarela(Vector3(101.0, 1.4, -161.0), Vector3(111.0, 1.4, -161.0), 3.8, true)
	_pasarela(Vector3(110.0, 1.4, -169.0), Vector3(110.0, 1.4, -153.0), 2.5, false)
	_bote(Vector3(113.0, 0.25, -156.0), 0.2)
	_bote(Vector3(106.5, 0.25, -166.5), -0.1)
	_cajas(Vector3(104.5, 1.45, -159.6))
	_red(_suelo(Vector2(91.0, -156.5)), 0.4, false)

	_cartel_en(Vector2(62.5, -156.0), "Puerto Albor", deg_to_rad(-30))
	_puesto(Vector2(84.0, -156.0), deg_to_rad(180))
	_poste_con_luz(Vector2(66.0, -163.5))
	_poste_con_luz(Vector2(92.0, -164.5))


func _cayo_de_salcristal() -> void:
	var orilla := _suelo(Vector2(110.0, -181.5), 0.05)
	_pasarela(orilla, Vector3(110.0, 1.4, -176.0), 2.4, true)
	_bote(Vector3(112.6, 0.25, -175.5), 0.1)
	_cartel_en(Vector2(106.5, -183.0), "Cayo de Salcristal", deg_to_rad(20))
	_roca_en(Vector2(117.0, -190.0), Vector3(2.4, 1.3, 1.8), 0.6)
	_roca_en(Vector2(104.5, -188.5), Vector3(1.8, 1.0, 1.5), -0.5)


# PROVISIONAL: el documento no describe la gruta; es una cámara de roca con
# la boca hacia el sendero.
func _gruta_olvidada() -> void:
	var boca := _suelo(TRAZADO.GRUTA)
	var gruta := _soporte(boca)
	var largo := 11.0
	var ancho := 3.4
	var alto := 3.2
	for lado in [-1.0, 1.0]:
		_bloque(gruta, Vector3(lado * (ancho * 0.5 + 0.6), alto * 0.5, -largo * 0.5), Vector3(1.2, alto + 1.0, largo), _piedra, true)
	_bloque(gruta, Vector3(0, alto + 0.5, -largo * 0.5), Vector3(ancho + 2.4, 1.0, largo), _piedra, true)
	_bloque(gruta, Vector3(0, alto * 0.5, -largo - 0.5), Vector3(ancho + 2.4, alto + 1.0, 1.0), _piedra, true)
	_bloque(gruta, Vector3(0, -0.05, -largo * 0.5), Vector3(ancho + 1.2, 0.1, largo), _madera_oscura, true)
	# Montículo de tierra sobre la cámara para que parezca metida en la ladera.
	var loma := SphereMesh.new()
	loma.radius = 0.5
	loma.height = 1.0
	loma.radial_segments = 7
	loma.rings = 3
	var monte := _mostrar(gruta, loma, Vector3(0, alto + 0.4, -largo * 0.55), _verde)
	monte.scale = Vector3(ancho + 6.0, 3.0, largo + 4.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("7fd8ff")
	luz.light_energy = 0.9
	luz.omni_range = 5.0
	gruta.add_child(luz)
	luz.position = Vector3(0, 1.4, -largo + 1.5)


func _hojas_flotantes(centro: Vector2, radio: float, semilla: int) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var hoja := CylinderMesh.new()
	hoja.top_radius = 0.29
	hoja.bottom_radius = 0.27
	hoja.height = 0.022
	hoja.radial_segments = 7
	var clara := _color(Color("788e49"))
	var oscura := _color(Color("526c3c"))
	for i in 33:
		var giro := azar.randf_range(0.0, TAU)
		var punto := centro + Vector2.from_angle(giro) * radio * sqrt(azar.randf())
		var altura := terreno.altura_en(punto.x, punto.y)
		if altura > -0.19 or altura < -0.65 or TRAZADO.distancia_a_camino(punto) < 2.35:
			continue
		var tono := clara if i % 3 == 0 else oscura
		var mat := _mostrar(self, hoja, Vector3(punto.x, 0.023, punto.y), tono)
		mat.rotation.y = giro
		mat.scale = Vector3(azar.randf_range(0.72, 1.21), 1.0, azar.randf_range(0.82, 1.40))
		mat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _casa(punto: Vector2, planta: Vector2, alto: float, giro: float, pared: Material, tejado: Material) -> void:
	var casa := _soporte(_suelo(punto), giro)
	var ancho := planta.x
	var fondo := planta.y
	_bloque(casa, Vector3(0, -0.12, 0), Vector3(ancho + 0.22, 0.70, fondo + 0.22), _piedra, true)
	_bloque(casa, Vector3(0, 0.20 + alto * 0.5, 0), Vector3(ancho, alto, fondo), pared, true)
	var profundo := -fondo * 0.5
	var alto_techo := ancho * 0.27
	var forma := PrismMesh.new()
	forma.size = Vector3(ancho + 0.74, alto_techo, fondo + 0.72)
	_mostrar(casa, forma, Vector3(0, 0.20 + alto + alto_techo * 0.5, 0), tejado)
	_bloque(casa, Vector3(0, alto + alto_techo + 0.20, 0), Vector3(0.16, 0.14, fondo + 0.88), _teja_oscura)
	for x in [-ancho * 0.5 + 0.11, ancho * 0.5 - 0.11]:
		for z in [profundo - 0.03, -profundo + 0.03]:
			_bloque(casa, Vector3(x, alto * 0.5 + 0.20, z), Vector3(0.21, alto, 0.18), _madera)
	_bloque(casa, Vector3(0, alto + 0.16, profundo - 0.07), Vector3(ancho + 0.2, 0.19, 0.20), _madera_oscura)
	_bloque(casa, Vector3(0.05, 1.02, profundo - 0.082), Vector3(1.1, 1.84, 0.19), _madera_oscura)
	_bloque(casa, Vector3(0.05, 0.98, profundo - 0.186), Vector3(0.83, 1.60, 0.13), _madera)
	_bloque(casa, Vector3(0.38, 1.03, profundo - 0.269), Vector3(0.08, 0.084, 0.065), _vidrio)

	for x in [-ancho * 0.29, ancho * 0.29]:
		_ventana(casa, Vector3(x, alto * 0.59, profundo - 0.07))
		_ventana(casa, Vector3(x, alto * 0.59, -profundo + 0.07), PI)


func _ventana(padre: Node3D, punto: Vector3, giro := 0.0) -> void:
	var ventana := Node3D.new()
	padre.add_child(ventana)
	ventana.position = punto
	ventana.rotation.y = giro
	_bloque(ventana, Vector3.ZERO, Vector3(0.98, 0.86, 0.16), _madera_oscura)
	_bloque(ventana, Vector3(0, 0, -0.09), Vector3(0.68, 0.56, 0.075), _vidrio)
	_bloque(ventana, Vector3(0, 0, -0.14), Vector3(0.075, 0.56, 0.052), _madera_oscura)
	_bloque(ventana, Vector3(0, -0.43, -0.033), Vector3(1.08, 0.1, 0.26), _madera_clara)


func _pasarela(inicio: Vector3, fin: Vector3, ancho: float, baranda: bool) -> void:
	var linea := fin - inicio
	var largo := linea.length()
	var base := Node3D.new()
	add_child(base)
	base.transform = Transform3D(Basis.looking_at(linea, Vector3.UP), inicio.lerp(fin, 0.5))
	_bloque(base, Vector3(0, -0.18, 0), Vector3(ancho, 0.36, largo + 0.06), _madera_oscura, true)
	var tablones := ceili(largo / 0.57)
	for fila in tablones:
		var largo_tablon := largo / float(tablones)
		var z := (float(fila) + 0.5) * largo_tablon - largo * 0.5
		var color := _madera if fila % 4 == 1 else _madera_clara
		_bloque(base, Vector3(0, 0, z), Vector3(ancho + 0.10, 0.084, largo_tablon - 0.026), color)
	var tramos := maxi(1, ceili(largo / 3.8))
	for lado in [-1.0, 1.0]:
		var x: float = lado * (ancho * 0.5 - 0.11)
		for poste in tramos + 1:
			var z := (float(poste) / float(tramos) - 0.5) * (largo - 0.5)
			_bloque(base, Vector3(x, -0.95, z), Vector3(0.24, 2.65, 0.24), _madera_oscura)
			if baranda:
				_bloque(base, Vector3(x, 0.48, z), Vector3(0.235, 1.04, 0.26), _madera)
		if baranda:
			_bloque(base, Vector3(x, 0.83, 0), Vector3(0.10, 0.12, largo - 0.65), _madera, true)


func _bote(posicion: Vector3, giro: float) -> void:
	var bote := _soporte(posicion, giro)
	_bloque(bote, Vector3(0, -0.10, 0), Vector3(1.52, 0.22, 3.0), _madera)
	for lado in [-1.0, 1.0]:
		var banda := _bloque(bote, Vector3(lado * 0.75, 0.13, 0), Vector3(0.20, 0.43, 2.92), _madera_clara)
		banda.rotation.z = -lado * 0.21
		for proa in [-1.0, 1.0]:
			var punta := _bloque(bote, Vector3(lado * 0.41, 0.16, proa * 1.72), Vector3(0.19, 0.46, 0.95), _madera)
			punta.rotation.y = -lado * proa * 0.82
	for z in [-0.72, 0.61]:
		_bloque(bote, Vector3(0, 0.19, z), Vector3(1.43, 0.09, 0.28), _madera_oscura)


func _cajas(posicion: Vector3) -> void:
	var pila := _soporte(posicion, 0.19)
	_bloque(pila, Vector3(-0.45, 0.36, 0), Vector3(0.80, 0.76, 0.64), _madera, true)
	_bloque(pila, Vector3(0.28, 0.25, 0.12), Vector3(0.63, 0.53, 0.58), _madera_clara, true)
	_bloque(pila, Vector3(-0.43, 0.78, -0.02), Vector3(0.82, 0.10, 0.67), _madera_clara)
	_bloque(pila, Vector3(0.30, 0.54, 0.12), Vector3(0.66, 0.09, 0.60), _madera_oscura)


func _red(posicion: Vector3, giro: float, rota: bool) -> void:
	var red := _soporte(posicion, giro)
	for lado in [-1.0, 1.0]:
		_bloque(red, Vector3(1.42 * lado, 0.78, 0), Vector3(0.16, 1.65, 0.16), _madera_oscura)
	_bloque(red, Vector3(0, 1.37, 0), Vector3(2.95, 0.075, 0.08), _madera_clara)
	for cuerda in 11:
		var x := float(cuerda - 5) * 0.22
		var alto := 0.24 + absf(x) * 0.38 if rota else 0.89
		var vertical := _bloque(red, Vector3(x, 1.36 - alto * 0.5, 0.022), Vector3(0.038, alto, 0.039), _madera_clara)
		vertical.rotation.z = x * 0.09
	for fila in (2 if rota else 4):
		var ancho := 2.46 if fila == 0 or not rota else 1.54
		var horizontal := _bloque(red, Vector3(0, 1.21 - fila * 0.18, 0.02), Vector3(ancho, 0.038, 0.041), _madera_clara)
		horizontal.rotation.z = -0.16 if rota else 0.0


func _puesto(punto: Vector2, giro: float) -> void:
	var puesto := _soporte(_suelo(punto), giro)
	for x in [-1.6, 1.6]:
		for z in [-0.85, 0.85]:
			_bloque(puesto, Vector3(x, 1.25, z), Vector3(0.13, 2.75, 0.13), _madera_oscura)
	var toldo := _bloque(puesto, Vector3(0, 2.39, 0), Vector3(3.75, 0.12, 2.4), _verde)
	toldo.rotation.x = -0.11
	_bloque(puesto, Vector3(0, 0.87, 0.45), Vector3(2.90, 0.17, 0.75), _madera_clara, true)
	_bloque(puesto, Vector3(-1.0, 0.37, 0.64), Vector3(0.54, 0.79, 0.48), _madera)
	_bloque(puesto, Vector3(0.88, 0.42, 0.62), Vector3(0.50, 0.79, 0.48), _madera)


func _poste_con_luz(punto: Vector2) -> void:
	var poste := _soporte(_suelo(punto))
	_bloque(poste, Vector3(0, 1.38, 0), Vector3(0.18, 2.78, 0.18), _madera_oscura)
	_bloque(poste, Vector3(-0.24, 2.68, 0), Vector3(0.56, 0.14, 0.14), _madera)
	_bloque(poste, Vector3(-0.42, 2.43, 0), Vector3(0.22, 0.34, 0.22), _vidrio)
	_bloque(poste, Vector3(-0.42, 2.62, 0), Vector3(0.29, 0.10, 0.29), _madera_oscura)


func _cartel_en(punto: Vector2, texto: String, giro: float) -> void:
	var cartel := _soporte(_suelo(punto), giro)
	var ancho := maxf(1.75, float(texto.length()) * 0.112 + 0.32)
	_bloque(cartel, Vector3(0, 0.92, 0), Vector3(0.14, 1.84, 0.15), _madera_oscura)
	_bloque(cartel, Vector3(0, 1.63, 0), Vector3(ancho, 0.43, 0.17), _cartel)
	for lado in [-1.0, 1.0]:
		var letras := Label3D.new()
		letras.text = texto
		letras.pixel_size = 0.006
		letras.font_size = 32
		letras.outline_size = 3
		letras.modulate = Color("f5e1ad")
		cartel.add_child(letras)
		letras.position = Vector3(0, 1.63, lado * 0.095)
		letras.rotation.y = 0.0 if lado > 0.0 else PI


func _roca_en(punto: Vector2, tamano: Vector3, giro: float) -> void:
	var roca := _soporte(_suelo(punto, tamano.y * 0.20), giro)
	var forma := SphereMesh.new()
	forma.radius = 0.5
	forma.height = 1.0
	forma.radial_segments = 6
	forma.rings = 2
	var malla := _mostrar(roca, forma, Vector3.ZERO, _piedra)
	malla.scale = tamano
	malla.rotation.z = 0.18
	if tamano.y > 1.2:
		var medidas := tamano * Vector3(0.67, 0.66, 0.67)
		_colision(roca, Vector3.ZERO, medidas)


func _plantar_juncos(centro: Vector2, radio: float, semilla: int) -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var hoja := _color(Color("6f8053"))
	var flor := _color(Color("a59559"))
	for intento in 85:
		var angulo := azar.randf_range(0, TAU)
		var punto := centro + Vector2.from_angle(angulo) * sqrt(azar.randf()) * radio
		var altura := terreno.altura_en(punto.x, punto.y)
		if altura < -0.25 or altura > 0.52 or not terreno.admite_vegetacion(punto):
			continue
		var mata := _soporte(Vector3(punto.x, altura, punto.y), angulo)
		for tallo in 3:
			var alto := azar.randf_range(0.50, 1.04)
			var x := (float(tallo) - 1.0) * 0.17
			var brote := _bloque(mata, Vector3(x, alto * 0.48, 0), Vector3(0.055, alto, 0.061), hoja)
			brote.rotation.z = x * 1.4
			if tallo == 1:
				_bloque(mata, Vector3(x, alto, 0), Vector3(0.095, 0.20, 0.092), flor)


func _suelo(punto: Vector2, desnivel := 0.0) -> Vector3:
	return Vector3(punto.x, terreno.altura_en(punto.x, punto.y) + desnivel, punto.y)


func _soporte(posicion: Vector3, giro := 0.0) -> Node3D:
	var soporte := Node3D.new()
	add_child(soporte)
	soporte.position = posicion
	soporte.rotation.y = giro
	return soporte


func _color(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TOON
	material.set_shader_parameter(&"color", color)
	return material


func _bloque(padre: Node3D, posicion: Vector3, medidas: Vector3, material: Material, solido := false) -> MeshInstance3D:
	var caja := BoxMesh.new()
	caja.size = medidas
	if solido:
		_colision(padre, posicion, medidas)
	return _mostrar(padre, caja, posicion, material)


func _mostrar(padre: Node3D, forma: Mesh, posicion: Vector3, material: Material) -> MeshInstance3D:
	var malla := MeshInstance3D.new()
	malla.mesh = forma
	malla.material_override = material
	malla.position = posicion
	padre.add_child(malla)
	return malla


func _colision(padre: Node3D, posicion: Vector3, medidas: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.position = posicion
	var volumen := BoxShape3D.new()
	volumen.size = medidas
	var forma := CollisionShape3D.new()
	forma.shape = volumen
	cuerpo.add_child(forma)
	padre.add_child(cuerpo)
