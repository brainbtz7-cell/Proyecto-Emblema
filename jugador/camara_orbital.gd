extends Node3D
## Cámara en tercera persona que orbita alrededor del protagonista.
##
## Se mueve con el ratón (clic para capturarlo, Esc para soltarlo; también
## arrastrando con el botón derecho) o con la palanca derecha del mando.
## La rueda del ratón acerca y aleja.

## A quién sigue la cámara. Si queda vacío, sigue al nodo padre.
@export var objetivo: Node3D
## Altura sobre los pies del objetivo a la que apunta la cámara.
@export var altura_de_mira := 1.0

@export_group("Control")
@export var sensibilidad_del_raton := 0.002
@export var sensibilidad_del_mando := 2.6
## Hasta dónde puede mirar hacia abajo y hacia arriba, en grados.
@export_range(-89.0, 0.0) var inclinacion_minima := -65.0
@export_range(0.0, 89.0) var inclinacion_maxima := 15.0

@export_group("Distancia")
@export var distancia := 8.0
@export var distancia_minima := 3.5
@export var distancia_maxima := 13.0
## Cuánto se abre la lente al correr.
@export var apertura_al_correr := 4.0

@export_group("Seguimiento")
## Qué tan rápido alcanza al objetivo. En vertical es más lenta para que los
## saltos no sacudan la imagen.
@export var rapidez_horizontal := 16.0
@export var rapidez_vertical := 7.0

@export_group("Follaje")
## Radio, en metros, de la ventana que se abre en el follaje cuando tapa al
## objetivo. En 0 no se abre.
@export var ventana_en_el_follaje := 1.7

var _rival: Node3D
var _giro_de_combate := 0.0
var _orbita_anterior := Vector2.ZERO
var _fov_de_exploracion := 42.0
var impulso_de_carrera := 0.0

@onready var brazo: SpringArm3D = $Brazo
@onready var _lente: Camera3D = $Brazo/Lente


func _ready() -> void:
	if objetivo == null:
		objetivo = get_parent() as Node3D
	brazo.spring_length = distancia
	_fov_de_exploracion = _lente.fov
	rotation.y = objetivo.global_rotation.y
	centrar()


func _unhandled_input(evento: InputEvent) -> void:
	if _rival or Interfaz.mapa_abierto:
		return
	var boton := evento as InputEventMouseButton
	var movimiento := evento as InputEventMouseMotion
	if boton and boton.pressed:
		match boton.button_index:
			MOUSE_BUTTON_LEFT:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			MOUSE_BUTTON_WHEEL_UP:
				distancia = maxf(distancia - 0.75, distancia_minima)
			MOUSE_BUTTON_WHEEL_DOWN:
				distancia = minf(distancia + 0.75, distancia_maxima)
	elif movimiento:
		var capturado := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		var arrastrando := (movimiento.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0
		if capturado or arrastrando:
			# screen_relative no cambia con el tamaño de la ventana; relative sí.
			var desplazamiento := movimiento.screen_relative * sensibilidad_del_raton
			_girar(-desplazamiento.x, -desplazamiento.y)


func _process(delta: float) -> void:
	var palanca := Input.get_vector("camara_izquierda", "camara_derecha", "camara_arriba", "camara_abajo")
	if _rival:
		var ajuste := 1.0 - exp(-11.0 * delta)
		rotation.y = lerp_angle(rotation.y, _giro_de_combate, ajuste)
		brazo.rotation.x = lerpf(brazo.rotation.x, deg_to_rad(-20.0), ajuste)
	elif palanca != Vector2.ZERO and not Interfaz.mapa_abierto:
		_girar(-palanca.x * sensibilidad_del_mando * delta, -palanca.y * sensibilidad_del_mando * delta)

	var distancia_objetivo := 5.8 if _rival else distancia
	brazo.spring_length = lerpf(brazo.spring_length, distancia_objetivo, 1.0 - exp(-10.0 * delta))
	var fov := _fov_de_exploracion
	if not _rival:
		fov += apertura_al_correr * impulso_de_carrera
	_lente.fov = lerpf(_lente.fov, fov, 1.0 - exp(-7.0 * delta))

	var jugador := _punto_de_mira()
	var mira := jugador
	var hierba_del_rival := Vector4.ZERO
	if _rival:
		var rival := _rival.get_global_transform_interpolated().origin
		mira = jugador.lerp(rival + Vector3.UP * 0.8, 0.5)
		# Reserva la parte baja de la pantalla para el panel de combate.
		mira.y -= 0.82
		hierba_del_rival = Vector4(rival.x, rival.y, rival.z, 2.35)
	var horizontal := 1.0 - exp(-rapidez_horizontal * delta)
	var vertical := 1.0 - exp(-rapidez_vertical * delta)
	global_position = Vector3(
		lerpf(global_position.x, mira.x, horizontal),
		lerpf(global_position.y, mira.y, vertical),
		lerpf(global_position.z, mira.z, horizontal))

	# Les cuenta a los shaders dónde está el objetivo (ver shaders/follaje.gdshader).
	RenderingServer.global_shader_parameter_set(&"protagonista", Vector4(jugador.x, jugador.y, jugador.z, ventana_en_el_follaje))
	RenderingServer.global_shader_parameter_set(&"rival_de_combate", hierba_del_rival)


## Encuadra a ambos de costado con el mismo brazo que evita el terreno.
func encuadrar_combate(rival: Node3D) -> void:
	_rival = rival
	_orbita_anterior = Vector2(rotation.y, brazo.rotation.x)
	var hacia := rival.global_position - objetivo.global_position
	var costado := atan2(hacia.z, -hacia.x)
	if absf(angle_difference(rotation.y, costado)) > PI * 0.5:
		costado += PI
	_giro_de_combate = costado


func restaurar_exploracion() -> void:
	_rival = null
	rotation.y = _orbita_anterior.x
	brazo.rotation.x = _orbita_anterior.y


## Coloca la cámara de golpe sobre el objetivo, sin deslizarla hasta allí.
func centrar() -> void:
	if objetivo:
		global_position = _punto_de_mira()


func _punto_de_mira() -> Vector3:
	return objetivo.get_global_transform_interpolated().origin + Vector3.UP * altura_de_mira


func _girar(giro: float, inclinacion: float) -> void:
	rotation.y = wrapf(rotation.y + giro, -PI, PI)
	brazo.rotation.x = clampf(
		brazo.rotation.x + inclinacion,
		deg_to_rad(inclinacion_minima),
		deg_to_rad(inclinacion_maxima))
