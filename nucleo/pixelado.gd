extends Node
## Mantiene el mundo 3D en baja resolución, con píxeles cuadrados y nítidos.
##
## El 3D se dibuja en una imagen pequeña (unos 270 píxeles de alto) y se amplía
## sin suavizado: de ahí sale el aspecto "pixel 3D". La interfaz 2D no se ve
## afectada y queda nítida; se amplía en pasos enteros (ver _escalar_interfaz).
##
## Es un autoload: funciona en cualquier escena sin agregar nada a mano.
## En el juego, F2 y F3 cambian el tamaño del píxel para comparar estilos.

## Se emite cuando cambia el tamaño del píxel o el de la ventana.
signal cambiado

## Altos de imagen disponibles, del píxel más grueso al más fino.
const ALTOS_INTERNOS: Array[int] = [180, 216, 270, 360, 540]

## Godot no reduce la imagen 3D a menos de un décimo de la ventana, así que
## un píxel del juego nunca ocupa más de 10 píxeles de pantalla. En ventanas
## muy grandes, los altos más bajos de la lista pueden no alcanzarse.
const PIXEL_MAXIMO := 10

## Alto aproximado, en píxeles, de la imagen en la que se dibuja el mundo 3D.
var alto_interno := 270:
	set(valor):
		alto_interno = valor
		_actualizar()

## Cuántos píxeles de pantalla ocupa cada píxel del juego.
var tamano_de_pixel := 1

## Resolución real a la que se está dibujando el mundo 3D.
var resolucion_interna := Vector2i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ventana := get_window()
	ventana.scaling_3d_mode = Viewport.SCALING_3D_MODE_NEAREST
	ventana.size_changed.connect(_actualizar)
	_actualizar()


func _unhandled_key_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pixel_mas_grande"):
		cambiar_alto(-1)
	elif evento.is_action_pressed("pixel_mas_chico"):
		cambiar_alto(1)


func cambiar_alto(pasos: int) -> void:
	var indice := ALTOS_INTERNOS.find(alto_interno)
	if indice == -1:
		indice = ALTOS_INTERNOS.find(270)
	alto_interno = ALTOS_INTERNOS[clampi(indice + pasos, 0, ALTOS_INTERNOS.size() - 1)]


func _actualizar() -> void:
	if not is_node_ready():
		return
	var ventana := get_window()
	# Un número entero de píxeles de pantalla por píxel de juego: así todos
	# los píxeles se ven del mismo tamaño.
	tamano_de_pixel = clampi(roundi(ventana.size.y / float(alto_interno)), 1, PIXEL_MAXIMO)
	ventana.scaling_3d_scale = 1.0 / tamano_de_pixel
	resolucion_interna = ventana.size / tamano_de_pixel
	_escalar_interfaz(ventana)
	cambiado.emit()


# La interfaz usa una fuente pixel (nítida en múltiplos de 20 px): con una escala
# entera, cada píxel de letra y de marco ocupa los mismos píxeles de pantalla.
# Si la ventana es más chica que el lienzo de referencia, se reduce sin redondear
# para que todo entre.
func _escalar_interfaz(ventana: Window) -> void:
	var lienzo := Vector2(ventana.content_scale_size)
	if lienzo.x <= 0.0 or lienzo.y <= 0.0:
		return
	var escala := minf(ventana.size.x / lienzo.x, ventana.size.y / lienzo.y)
	var modo := Window.CONTENT_SCALE_STRETCH_INTEGER if escala >= 1.0 else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	if ventana.content_scale_stretch != modo:
		ventana.content_scale_stretch = modo
