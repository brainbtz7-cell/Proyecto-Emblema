extends Control
## Plano local dibujado a partir de las alturas y el trazado de la escena jugable.

const TRAZADO := preload("res://mundo/salbruma/trazado_salbruma.gd")
const LOMOS := preload("res://encargos/puerto_junco_pescador_lomos.tres")
const EMBOSCADA := preload("res://encargos/puerto_junco_guardia_emboscada.tres")
const RESCATE := preload("res://encargos/puerto_junco_tablon_rescate.tres")
const MAREA := preload("res://encargos/puerto_junco_ultima_marea.tres")
const IMPOSTOR := preload("res://encargos/la_voz_desenmascara_al_impostor.tres")
const LETRA := preload("res://interfaz/fuentes/inter_regular.ttf")
const NEGRITA := preload("res://interfaz/fuentes/inter_semibold.ttf")
const SERIF := preload("res://interfaz/fuentes/cormorant_garamond.ttf")
const REGION := Rect2(-196, -185, 392, 257)
const PANEL := Vector2(1150, 676)
const LAMINA := Rect2(24, 84, 796, 522)
const CONTEXTO := Rect2(840, 84, 286, 522)
const CERRAR := Rect2(930, 620, 196, 38)
const TINTA := Color("172027")
const MARFIL := Color("f2e5c5")
const LATON := Color("d5b783")
const CLARO := Color("b6c2bc")
const SENDERO := Color("e9cca4")
const POSICION := Color("adf4f0")
const OTROS_DESTINOS := {
	&"puerto_junco_pescador_lomos": TRAZADO.BAJIOS,
	&"puerto_junco_guardia_asaltantes": TRAZADO.CALETA,
	&"puerto_junco_pescador_cuero": TRAZADO.MARISMAS,
}

@export var terreno: Terreno
@export var jugador: Jugador
## Distancia en metros al centro de Albor dentro de la que se muestra el nombre del pueblo.
@export_range(1.0, 100.0, 1.0) var radio_de_puerto_albor := 28.0
## Distancia en metros a cada lado del trazado donde se muestra Sendero de los Faros.
@export_range(1.0, 100.0, 1.0) var margen_del_sendero_de_los_faros := 24.0

var _base: ImageTexture
var _raton_anterior := Input.MOUSE_MODE_VISIBLE
var _volver := Button.new()
var _ubicacion := ""
var _primer_paso := ""
var _pausado_antes := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = preload("res://interfaz/tema.tres")
	Interfaz.establecer_mapa_disponible(true)
	Interfaz.solicitar_mapa.connect(_abrir)
	Interfaz.dispositivo_cambiado.connect(_actualizar_boton)
	_volver.theme_type_variation = &"BotonPrincipal"
	_volver.pressed.connect(_cerrar)
	add_child(_volver)
	resized.connect(_colocar_boton)
	_actualizar_ubicacion()


func _exit_tree() -> void:
	if is_instance_valid(Interfaz):
		if visible:
			_cerrar()
		Interfaz.establecer_mapa_disponible(false)


func _input(evento: InputEvent) -> void:
	if evento.is_echo():
		return
	if visible and (evento.is_action_pressed(&"ver_mapa") or evento.is_action_pressed(&"ui_cancel")):
		_cerrar()
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed(&"ver_mapa") and not Interfaz.ocupada():
		_abrir()
		get_viewport().set_input_as_handled()


func _abrir() -> void:
	if _base == null:
		_base = _dibujar_relieve()
	_raton_anterior = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pausado_antes = get_tree().paused
	get_tree().paused = true
	Interfaz.mapa_abierto = true
	show()
	Interfaz.animar_entrada(self)
	_colocar_boton()
	_actualizar_boton()
	_volver.grab_focus()


func _actualizar_boton() -> void:
	_volver.text = "%s   Volver al juego" % Interfaz.tecla(&"ver_mapa", Interfaz.con_mando)


func _colocar_boton() -> void:
	_volver.position = _origen_del_panel() + CERRAR.position * _escala()
	_volver.size = CERRAR.size
	_volver.scale = Vector2.ONE * _escala()


func _process(_delta: float) -> void:
	_actualizar_ubicacion()
	if _base and visible:
		queue_redraw()


func _actualizar_ubicacion() -> void:
	var posicion := Vector2(jugador.global_position.x, jugador.global_position.z)
	var lugar := "Tierras de Salbruma"
	var primer_paso := "Abrí el plano para orientarte."
	# El islote es una elipse de unos 14 × 9 m; se toma un poco más, con el muelle.
	if ((posicion - TRAZADO.CAYO) / Vector2(15.0, 11.0)).length() < 1.0:
		lugar = "Cayo de Salcristal"
		primer_paso = "El bote del muelle vuelve a Puerto Albor."
	elif posicion.distance_squared_to(TRAZADO.PUERTO_ALBOR) < radio_de_puerto_albor * radio_de_puerto_albor:
		lugar = "Puerto Albor"
		primer_paso = "Recorré el pueblo y su muelle."
	elif posicion.distance_squared_to(TRAZADO.PUERTO) < 32.0 * 32.0:
		lugar = "Puerto Junco"
		if Encargos.estado_de(LOMOS) == Encargos.Estado.DISPONIBLE:
			primer_paso = "Hablá con el pescador del muelle."
		elif Encargos.estado_de(MAREA) == Encargos.Estado.COMPLETADO:
			primer_paso = "El camino a Puerto Albor pasa por las marismas."
		else:
			primer_paso = "Buscá más encargos entre los habitantes o en el tablón."
	elif posicion.distance_squared_to(TRAZADO.CALETA) < 23.0 * 23.0:
		lugar = "Caleta de las Redes Rotas"
		primer_paso = "El camino de la ribera lleva a Puerto Junco."
	elif posicion.distance_squared_to(TRAZADO.MARISMAS) < 29.0 * 29.0:
		lugar = "Marismas del Caparazón"
		primer_paso = "El camino del norte continúa hacia el Sendero de los Faros."
	elif TRAZADO.distancia_a_tramo(posicion, TRAZADO.HACIA_ALBOR) < margen_del_sendero_de_los_faros:
		lugar = "Sendero de los Faros"
		primer_paso = "Seguí el sendero hacia Puerto Albor."
	elif posicion.distance_squared_to(TRAZADO.BAJIOS) < 34.0 * 34.0:
		lugar = "Bajíos de Salbruma"
		primer_paso = "Seguí el camino hacia el este para llegar a Puerto Junco."
	elif posicion.x < -103.0:
		lugar = "Llegada a Salbruma"
		primer_paso = "Seguí el sendero hasta Puerto Junco."
	if _ubicacion != lugar or _primer_paso != primer_paso:
		_ubicacion = lugar
		_primer_paso = primer_paso
		Interfaz.establecer_ubicacion(lugar, primer_paso)


func _cerrar() -> void:
	hide()
	get_tree().paused = _pausado_antes
	Input.mouse_mode = _raton_anterior
	Interfaz.registrar_cierre()
	Interfaz.mapa_abierto = false


func _escala() -> float:
	return minf((size.x - 30.0) / PANEL.x, (size.y - 24.0) / PANEL.y)


func _origen_del_panel() -> Vector2:
	return (size - PANEL * _escala()) * 0.5


func _draw() -> void:
	if _base == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.037, 0.058, 0.070, 0.72))
	draw_set_transform(_origen_del_panel(), 0.0, Vector2.ONE * _escala())
	draw_style_box(get_theme_stylebox(&"panel", &"PanelContainer"), Rect2(Vector2.ZERO, PANEL))

	draw_string(SERIF, Vector2(24, 55), "Tierras de Salbruma", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, MARFIL)
	draw_string(LETRA, Vector2(706, 53), "Puerto Junco y Puerto Albor", HORIZONTAL_ALIGNMENT_RIGHT, 420, 16, CLARO)
	draw_texture_rect(_base, LAMINA, false)
	_cuadricula()
	draw_rect(LAMINA, Color("746e58"), false, 1.0)

	_pintar_camino(TRAZADO.HACIA_MARISMAS, SENDERO, 3.2)
	_pintar_camino(TRAZADO.HACIA_ALBOR, SENDERO, 3.2)
	_pintar_camino(TRAZADO.CAMINO, SENDERO, 3.2)
	_pintar_camino(TRAZADO.RIBERA, SENDERO, 3.2)

	_rotulo(TRAZADO.LLEGADA, Vector2(-21, 34), "Llegada", 19, &"llegada")
	_rotulo(TRAZADO.BAJIOS, Vector2(-73, 47), "Bajíos de Salbruma", 24, &"bajios")
	_rotulo(TRAZADO.PUERTO, Vector2(-54, 47), "Puerto Junco", 27, &"pueblo")
	_rotulo(TRAZADO.CALETA, Vector2(-185, -20), "Caleta de las Redes Rotas", 22, &"caleta")
	_rotulo(TRAZADO.MARISMAS, Vector2(-112, -25), "Marismas del Caparazón", 23, &"bajios")
	_rotulo(TRAZADO.FAROS, Vector2(-91, 40), "Sendero de los Faros", 23)
	_rotulo(TRAZADO.PUERTO_ALBOR, Vector2(17, -13), "Puerto Albor", 27, &"pueblo")
	_escribir(_en_plano(Vector2(116, -6)), "Gran Río", 22, Color("b9eaec"))
	_norte()
	_dibujar_tercera_tanda()
	_dibujar_encargos()

	var posicion := Vector2(jugador.global_position.x, jugador.global_position.z)
	if REGION.has_point(posicion):
		var flecha := Vector2(-sin(jugador.modelo.global_rotation.y), -cos(jugador.modelo.global_rotation.y))
		_marcador(_en_plano(posicion), flecha)
	_dibujar_contexto()
	_escala_en_metros()


func _cuadricula() -> void:
	var tono := Color("17272b27")
	var paso := 25
	for este in range(ceili(REGION.position.x / paso) * paso, ceili(REGION.end.x), paso):
		var x := _en_plano(Vector2(este, 0)).x
		draw_line(Vector2(x, LAMINA.position.y), Vector2(x, LAMINA.end.y), tono, 1.0)
	for norte in range(ceili(REGION.position.y / paso) * paso, ceili(REGION.end.y), paso):
		var y := _en_plano(Vector2(0, norte)).y
		draw_line(Vector2(LAMINA.position.x, y), Vector2(LAMINA.end.x, y), tono, 1.0)


func _escala_en_metros() -> void:
	var punto := Vector2(24, 642)
	var longitud := LAMINA.size.x * 50.0 / REGION.size.x
	draw_line(punto, punto + Vector2(longitud, 0), LATON, 2.0)
	for x in [0.0, longitud * 0.5, longitud]:
		draw_line(punto + Vector2(x, -4), punto + Vector2(x, 4), LATON, 1.4)
	draw_string(LETRA, punto + Vector2(longitud + 10, 6), "50 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CLARO)


func _dibujar_contexto() -> void:
	draw_style_box(get_theme_stylebox(&"panel", &"PanelBitacora"), CONTEXTO)
	var x := CONTEXTO.position.x + 18.0
	var ancho := CONTEXTO.size.x - 36.0
	draw_string(NEGRITA, Vector2(x, 115), "Ubicación", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LATON)
	draw_multiline_string(SERIF, Vector2(x, 145), _ubicacion, HORIZONTAL_ALIGNMENT_LEFT, ancho, 29, 2, MARFIL)
	draw_line(Vector2(x, 190), Vector2(x + ancho, 190), Color("53615e"))
	draw_string(NEGRITA, Vector2(x, 221), "Encargos en curso", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, LATON)
	var abiertos := Encargos.en_curso()
	var y := 248.0
	if abiertos.is_empty():
		draw_multiline_string(LETRA, Vector2(x, y), "Los encargos aceptados se marcan en el plano.", HORIZONTAL_ALIGNMENT_LEFT, ancho, 15, 2, CLARO)
	for encargo in abiertos.slice(0, 3):
		var cumplido := Encargos.estado_de(encargo) == Encargos.Estado.CUMPLIDO
		var avance := "Volvé con %s" % encargo.entregar_a if cumplido else "%d/%d  ·  %s" % [
			Encargos.avance_de(encargo), encargo.cantidad, encargo.objetivo
		]
		var color := get_theme_color(&"font_color", &"EnfasisDeLaVoz") if encargo.de_la_voz else MARFIL
		draw_multiline_string(NEGRITA, Vector2(x, y), encargo.titulo, HORIZONTAL_ALIGNMENT_LEFT, ancho, 15, 2, color)
		draw_multiline_string(LETRA, Vector2(x, y + 36), avance, HORIZONTAL_ALIGNMENT_LEFT, ancho, 14, 2, CLARO)
		y += 76.0
	var fila := CONTEXTO.end.y - 57.0
	draw_line(Vector2(x, fila - 20), Vector2(x + ancho, fila - 20), Color("53615e"))
	_marcador(Vector2(x + 10, fila), Vector2.UP)
	draw_string(LETRA, Vector2(x + 28, fila + 5), "Tu posición", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MARFIL)
	_diamante(Vector2(x + 10, fila + 29))
	draw_string(LETRA, Vector2(x + 28, fila + 34), "Destino de encargo", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, MARFIL)


func _norte() -> void:
	var punto := Vector2(781, 127)
	var punta := PackedVector2Array([punto + Vector2(0, -18), punto + Vector2(-7, 5), punto + Vector2(0, 1), punto + Vector2(7, 5)])
	draw_colored_polygon(punta, MARFIL)
	_escribir(punto + Vector2(-7, 23), "N", 17, MARFIL)


func _pintar_camino(tramo: Array[Vector2], color: Color, grosor: float) -> void:
	var linea := PackedVector2Array()
	for punto in tramo:
		linea.append(_en_plano(punto))
	draw_polyline(linea, Color(0.13, 0.19, 0.19, 0.63), grosor + 2.8, true)
	draw_polyline(linea, color, grosor, true)


func _en_plano(punto: Vector2) -> Vector2:
	return LAMINA.position + (punto - REGION.position) / REGION.size * LAMINA.size


func _rotulo(punto: Vector2, margen: Vector2, texto: String, alto: int, simbolo: StringName = &"") -> void:
	var marca := _en_plano(punto)
	var rotulo := marca + margen
	var ancho := SERIF.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, alto).x
	var enlace := Vector2(clampf(marca.x, rotulo.x, rotulo.x + ancho), rotulo.y - (alto if margen.y > 0 else 0))
	draw_line(marca, enlace, Color(0.93, 0.86, 0.70, 0.60), 1.0, true)
	_dibujar_hito(marca, simbolo)
	_escribir(rotulo, texto, alto, MARFIL)


func _dibujar_hito(marca: Vector2, simbolo: StringName) -> void:
	if simbolo == &"encargo":
		_diamante(marca)
		return
	draw_circle(marca, 9.5 if simbolo else 5.5, TINTA, true, -1.0, true)
	match simbolo:
		&"llegada":
			var arcilla := Color("ecad85")
			draw_line(marca + Vector2(-4, -4), marca + Vector2(4, 4), arcilla, 2.1, true)
			draw_line(marca + Vector2(-4, 4), marca + Vector2(4, -4), arcilla, 2.1, true)
		&"bajios":
			for linea in [-2.8, 2.8]:
				var puntos := PackedVector2Array([marca + Vector2(-5, linea), marca + Vector2(-2, linea + 1), marca + Vector2(2, linea - 1), marca + Vector2(5, linea)])
				draw_polyline(puntos, Color("9ad6cf"), 1.5, true)
		&"pueblo":
			draw_rect(Rect2(marca + Vector2(-4, -0.5), Vector2(8, 5.7)), MARFIL)
			draw_colored_polygon(PackedVector2Array([marca + Vector2(-6, 0), marca + Vector2(0, -5), marca + Vector2(6, 0)]), MARFIL)
		&"caleta":
			var agua := Color("9ad6cf")
			draw_circle(marca + Vector2(0, -3.9), 2.0, agua, false, 1.3, true)
			draw_line(marca + Vector2(0, -2.3), marca + Vector2(0, 4.6), agua, 1.4, true)
			draw_polyline(PackedVector2Array([marca + Vector2(-5, 0.4), marca + Vector2(-3, 3.5), marca + Vector2(0, 4.7), marca + Vector2(3, 3.5), marca + Vector2(5, 0.4)]), agua, 1.45, true)
		_:
			draw_circle(marca, 3.1, MARFIL, true, -1.0, true)


func _escribir(punto: Vector2, texto: String, alto: int, color: Color) -> void:
	draw_string_outline(SERIF, punto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, alto, 5, Color(0.06, 0.11, 0.13, 0.86))
	draw_string(SERIF, punto, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, alto, color)


func _marcador(punto: Vector2, hacia: Vector2) -> void:
	draw_circle(punto, 11.2, TINTA, true, -1.0, true)
	draw_circle(punto, 9.0, POSICION, true, -1.0, true)
	var lado := hacia.orthogonal() * 3.4
	var flecha := PackedVector2Array([punto + hacia * 5.5, punto - hacia * 3.4 + lado, punto - hacia * 1.8, punto - hacia * 3.4 - lado])
	draw_colored_polygon(flecha, TINTA)


func _dibujar_encargos() -> void:
	var volver_a_junco := false
	for encargo in Encargos.en_curso():
		if encargo == IMPOSTOR:
			_diamante(_en_plano(TRAZADO.PUERTO_ALBOR) + Vector2(15, 15))
		elif Encargos.estado_de(encargo) == Encargos.Estado.CUMPLIDO:
			volver_a_junco = true
		elif OTROS_DESTINOS.has(encargo.id):
			_diamante(_en_plano(OTROS_DESTINOS[encargo.id]) + Vector2(14, -13))
	if volver_a_junco:
		_diamante(_en_plano(TRAZADO.PUERTO) + Vector2(14, -13))
	for defensa in get_tree().get_nodes_in_group(&"defensas_de_junco"):
		if defensa is DefensaDeJunco and defensa.pendiente():
			var punto := Vector2(defensa.global_position.x, defensa.global_position.z)
			_diamante(_en_plano(punto))


func _dibujar_tercera_tanda() -> void:
	if Encargos.estado_de(EMBOSCADA) == Encargos.Estado.ACTIVO:
		_pintar_camino(TRAZADO.INVESTIGACION, SENDERO, 2.7)
		_rotulo(TRAZADO.EMBOSCADA, Vector2(-185, -22), "Punto de investigación", 20, &"encargo")
	if Encargos.estado_de(RESCATE) == Encargos.Estado.ACTIVO:
		_pintar_camino(TRAZADO.HACIA_RESCATE, SENDERO, 2.7)
		if not Encargos.contado(RESCATE, &"liberar"):
			_rotulo(TRAZADO.RESCATE, Vector2(-93, -20), "Zona de rescate", 20, &"encargo")
		else:
			_diamante(_en_plano(TRAZADO.PUERTO) + Vector2(14, -13))
	if Encargos.estado_de(MAREA) == Encargos.Estado.ACTIVO:
		_rotulo(TRAZADO.ULTIMA_MAREA, Vector2(-157, -18), "Capitán Klaimyr", 20, &"encargo")


func _diamante(punto: Vector2) -> void:
	draw_circle(punto, 8.5, TINTA, true, -1.0, true)
	draw_colored_polygon(PackedVector2Array([
		punto + Vector2(0, -5), punto + Vector2(5, 0),
		punto + Vector2(0, 5), punto + Vector2(-5, 0),
	]), Color("f3cd7c"))


func _dibujar_relieve() -> ImageTexture:
	var ancho := 490
	var alto := roundi(ancho * REGION.size.y / REGION.size.x)
	var imagen := Image.create(ancho, alto, false, Image.FORMAT_RGB8)
	var paso := REGION.size / Vector2(ancho, alto)
	for j in alto:
		for i in ancho:
			var punto := REGION.position + (Vector2(i, j) + Vector2.ONE * 0.5) * paso
			var h := terreno.altura_en(punto.x, punto.y)
			imagen.set_pixel(i, j, _tono(punto, h))
	return ImageTexture.create_from_image(imagen)


func _tono(punto: Vector2, h: float) -> Color:
	if h < 0.0:
		var profundo := Color("295b72")
		var bajo := Color("74b3ab")
		if h > -0.15:
			return Color("84c3b5")
		return profundo.lerp(bajo, smoothstep(-5.5, -0.15, h))
	var h_luz := terreno.altura_en(punto.x - 1.1, punto.y - 1.1)
	var h_sombra := terreno.altura_en(punto.x + 1.1, punto.y + 1.1)
	var luz := clampf((h_sombra - h_luz) * 0.29, -0.23, 0.22)
	var tono := Color("829369").lerp(Color("556f59"), smoothstep(1.0, 13.0, h))
	tono = tono.lerp(Color("92938a"), smoothstep(13.0, 36.0, h))
	if h < 0.56:
		tono = Color("cbb589").lerp(tono, smoothstep(0.08, 0.56, h))
	tono = tono.lightened(luz) if luz > 0.0 else tono.darkened(-luz)
	if h > 3.0 and fposmod(h, 3.5) < 0.20:
		tono = tono.darkened(0.11)
	return tono
