class_name RotulosDePersonajes
extends Control
## Nombres de los personajes cercanos, dibujados con la fuente pixel sobre sus
## cabezas. Reemplazan a los rótulos 3D, que en el mundo pixelado se veían como
## garabatos de lejos y enormes de cerca.
##
## Cada DadorDeEncargos se anota en el grupo "personajes_con_nombre"; los que no
## deben mostrar nombre (una víctima, una nota) tienen mostrar_nombre en false.

const PIXEL := preload("res://interfaz/fuentes/pixelify_sans.ttf")
## Tamaño de letra: la fuente pixel es nítida en múltiplos de 20.
const TAMANO := 20
const COLOR := Color(0.97, 0.93, 0.83)
const CONTORNO := Color(0.03, 0.05, 0.06, 0.85)

## Distancia en metros al protagonista hasta la que el nombre se ve entero.
@export_range(1.0, 20.0, 0.5) var distancia_plena := 6.0
## Distancia en metros a la que el nombre termina de desvanecerse.
@export_range(1.0, 30.0, 0.5) var distancia_maxima := 9.0
## Altura en metros del nombre sobre los pies del personaje, encima del globo.
@export_range(1.0, 4.0, 0.05) var altura := 2.7


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var camara := get_viewport().get_camera_3d()
	var escena := get_tree().current_scene
	if camara == null or escena == null:
		return
	var jugador := escena.get_node_or_null(^"Jugador") as Node3D
	var centro := jugador.global_position if jugador else camara.global_position
	# Del más cercano al más lejano; si un nombre taparía a otro ya dibujado, se omite.
	var cercanos: Array[Array] = []
	for personaje in get_tree().get_nodes_in_group(&"personajes_con_nombre"):
		var cuerpo := personaje as Node3D
		if cuerpo == null or not cuerpo.is_visible_in_tree() or not cuerpo.get(&"mostrar_nombre"):
			continue
		var distancia := cuerpo.global_position.distance_to(centro)
		if distancia <= distancia_maxima:
			cercanos.append([distancia, cuerpo])
	cercanos.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var ocupados: Array[Rect2] = []
	for par in cercanos:
		var cuerpo: Node3D = par[1]
		var punto := cuerpo.global_position + Vector3.UP * altura
		if camara.is_position_behind(punto):
			continue
		var texto: String = cuerpo.get(&"nombre")
		var medida := PIXEL.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO)
		var base := (camara.unproject_position(punto) - Vector2(medida.x * 0.5, 0.0)).round()
		var caja := Rect2(base - Vector2(4, medida.y), medida + Vector2(8, 4))
		if ocupados.any(func(otra: Rect2) -> bool: return otra.intersects(caja)):
			continue
		ocupados.append(caja)
		var alfa := clampf(inverse_lerp(distancia_maxima, distancia_plena, par[0]), 0.0, 1.0)
		draw_string_outline(PIXEL, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, 4, Color(CONTORNO, CONTORNO.a * alfa))
		draw_string(PIXEL, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANO, Color(COLOR, alfa))
