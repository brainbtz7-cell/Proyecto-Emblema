class_name Figura
extends Node3D
## Figura del protagonista y su animación.
##
## Es un marcador de posición: alguien encapuchado, con túnica hasta el suelo,
## que no define raza ni rasgos. No tiene huesos: cada parte se mueve con
## fórmulas sencillas. El script del jugador le cuenta qué pasa (camina,
## salta, aterriza) y la figura decide cómo moverse.

@export_group("Caminar")
## Qué tan rápido gira el cuerpo hacia donde camina.
@export var rapidez_de_giro := 14.0
## Cuánto avanza el ciclo de pasos por cada metro recorrido.
@export var pasos_por_metro := 2.0
## Altura del rebote en cada paso, en metros.
@export var rebote := 0.07
## Cuánto se mece de lado a lado al caminar, en radianes.
@export var vaiven := 0.07
## Cuánto se inclina hacia adelante al correr, en radianes.
@export var inclinacion := 0.16
## Cuánto se balancean los brazos, en radianes.
@export var balanceo_de_brazos := 0.7

@export_group("En el aire")
## Cuánto se abren los brazos al saltar, en radianes.
@export var apertura_de_brazos := 0.95
## Segundos que dura la vuelta del doble salto.
@export var duracion_de_la_vuelta := 0.42

@export_group("Túnica y capa")
## Cuánto se mece la falda de la túnica al caminar, en radianes.
@export var vaiven_de_la_falda := 0.06
## Ángulo de la capa en reposo, en radianes.
@export var caida_de_la_capa := 0.07
## Cuánto se levanta la capa al correr.
@export var vuelo_de_la_capa := 0.9

@export_group("Sonido")
## Debajo de esta altura los pasos suenan a agua; hasta "altura_de_arena", a arena.
@export var altura_de_agua := 0.0
@export var altura_de_arena := 0.7

var _ultimo_paso := 0
var _ambiente_iniciado := false

## Aporte de la animación de combate a la postura de cada brazo.
var golpe_de_combate := 0.0
var guardia_de_combate := 0.0

var _tiempo := 0.0
var _fase_de_paso := 0.0
var _marcha := 0.0
var _en_el_aire := 0.0
var _avance_de_la_vuelta := 1.0
var _proximo_parpadeo := 3.0

@onready var _inclinacion: Node3D = $Inclinacion
@onready var _giro: Node3D = $Inclinacion/Giro
@onready var _torso: Node3D = $Inclinacion/Giro/Torso
@onready var _cabeza: Node3D = $Inclinacion/Giro/Torso/Cabeza
@onready var _brazo_izquierdo: Node3D = $Inclinacion/Giro/Torso/BrazoIzquierdo
@onready var _brazo_derecho: Node3D = $Inclinacion/Giro/Torso/BrazoDerecho
@onready var _falda: Node3D = $Inclinacion/Giro/Falda
@onready var _capa: Node3D = $Inclinacion/Giro/Torso/Capa
@onready var _capa_media: Node3D = $Inclinacion/Giro/Torso/Capa/CapaMedia
@onready var _capa_baja: Node3D = $Inclinacion/Giro/Torso/Capa/CapaMedia/CapaBaja
@onready var _ojos: Node3D = $Inclinacion/Giro/Torso/Cabeza/Ojos


## Se llama en cada paso de física con el estado del protagonista.
## "direccion" es hacia dónde quiere ir (vector vacío si no se mueve).
func animar(delta: float, velocidad: Vector3, velocidad_maxima: float, en_el_suelo: bool, direccion: Vector3, carrera := 0.0) -> void:
	_tiempo += delta
	var rapidez := Vector2(velocidad.x, velocidad.z).length()
	var esfuerzo := clampf(rapidez / velocidad_maxima, 0.0, 1.0)

	if direccion.length_squared() > 0.001:
		var angulo := atan2(-direccion.x, -direccion.z)
		global_rotation.y = lerp_angle(global_rotation.y, angulo, _hacia(rapidez_de_giro, delta))

	# Dos medidas suaves, de 0 a 1: cuánto camina y cuánto está en el aire.
	_marcha = lerpf(_marcha, esfuerzo if en_el_suelo else 0.0, _hacia(10.0, delta))
	_en_el_aire = lerpf(_en_el_aire, 0.0 if en_el_suelo else 1.0, _hacia(12.0, delta))
	if en_el_suelo:
		_fase_de_paso += delta * rapidez * pasos_por_metro
		# Cada medio ciclo apoya un pie.
		var pisada := int(_fase_de_paso / PI)
		if pisada != _ultimo_paso:
			_ultimo_paso = pisada
			if rapidez > 0.5:
				Sonido.efecto_en(_superficie(), global_position)
	if not _ambiente_iniciado and is_inside_tree():
		_ambiente_iniciado = true
		Sonido.iniciar_ambiente(get_tree())
	var paso := sin(_fase_de_paso)
	var respiracion := sin(_tiempo * 2.2)

	# Cuerpo: rebota y se mece con cada paso, se inclina al correr y vuelve
	# de a poco a su forma tras estirarse o aplastarse en un salto.
	position.y = absf(paso) * rebote * _marcha
	scale = scale.lerp(Vector3.ONE, _hacia(11.0, delta))
	_inclinacion.rotation.x = lerpf(_inclinacion.rotation.x, -inclinacion * (esfuerzo + carrera * 0.75), _hacia(10.0, delta))
	_inclinacion.rotation.z = paso * vaiven * _marcha
	_torso.scale.y = 1.0 + respiracion * 0.015 * (1.0 - _marcha)

	# Falda: se mece al revés que el cuerpo y queda un poco atrás al correr.
	_falda.rotation.z = -paso * vaiven_de_la_falda * _marcha
	_falda.rotation.x = lerpf(_falda.rotation.x, -0.1 * esfuerzo, _hacia(6.0, delta))

	# Cabeza: mira hacia arriba al subir y hacia abajo al caer.
	var mirada := clampf(velocidad.y * 0.03, -0.3, 0.3) * _en_el_aire
	_cabeza.rotation.x = lerpf(_cabeza.rotation.x, mirada, _hacia(8.0, delta))

	# Brazos: se balancean al caminar y se abren en el aire.
	var balanceo := paso * balanceo_de_brazos * _marcha
	var apertura := 0.14 + respiracion * 0.02 + apertura_de_brazos * _en_el_aire
	var hacia_adelante := -0.35 * _en_el_aire
	_brazo_izquierdo.rotation = Vector3(balanceo + hacia_adelante + guardia_de_combate, 0.0, -apertura)
	_brazo_derecho.rotation = Vector3(-balanceo + hacia_adelante + guardia_de_combate + golpe_de_combate, 0.0, apertura)

	# Capa: queda atrás al correr, se levanta al caer y ondea siempre un poco.
	# Son tres tramos; los de abajo reaccionan más lento, así la tela se curva.
	var por_caida := clampf(-velocidad.y * 0.07, -0.2, 1.1) * _en_el_aire
	var por_vuelta := sin(_avance_de_la_vuelta * PI) * 0.7
	var vuelo := vuelo_de_la_capa * (_marcha + carrera * 0.24) + por_caida + por_vuelta
	var ritmo := _tiempo * (3.0 + 6.0 * esfuerzo)
	var amplitud := 0.03 + 0.06 * esfuerzo
	_capa.rotation.x = lerpf(_capa.rotation.x, -(caida_de_la_capa + vuelo * 0.55 + sin(ritmo) * amplitud), _hacia(9.0, delta))
	_capa_media.rotation.x = lerpf(_capa_media.rotation.x, -(0.1 + vuelo * 0.3 + sin(ritmo - 0.9) * amplitud * 1.5), _hacia(6.0, delta))
	_capa_baja.rotation.x = lerpf(_capa_baja.rotation.x, -(0.1 + vuelo * 0.3 + sin(ritmo - 1.8) * amplitud * 2.0), _hacia(4.0, delta))

	# Vuelta completa del doble salto.
	if _avance_de_la_vuelta < 1.0:
		_avance_de_la_vuelta = minf(_avance_de_la_vuelta + delta / duracion_de_la_vuelta, 1.0)
		_giro.rotation.y = TAU * ease(_avance_de_la_vuelta, 0.4)
	else:
		_giro.rotation.y = 0.0

	# Parpadeo.
	_proximo_parpadeo -= delta
	_ojos.visible = _proximo_parpadeo > 0.0
	if _proximo_parpadeo < -0.12:
		_proximo_parpadeo = randf_range(2.0, 5.0)


func al_saltar() -> void:
	scale = Vector3(0.8, 1.25, 0.8)
	Sonido.efecto(&"salto")


func al_doble_salto() -> void:
	scale = Vector3(0.85, 1.2, 0.85)
	_avance_de_la_vuelta = 0.0
	Sonido.efecto(&"doble_salto")


func al_aterrizar() -> void:
	scale = Vector3(1.25, 0.75, 1.25)
	Sonido.efecto(&"aterrizaje")


# Qué suena al pisar: roca sobre rocas y construcciones; sobre el terreno,
# agua, arena o pasto según la altura.
func _superficie() -> StringName:
	if global_position.y < altura_de_agua:
		return &"paso_agua"
	var espacio := get_world_3d().direct_space_state
	var consulta := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 0.6, Suelo.CAPA_DEL_MUNDO)
	var golpe := espacio.intersect_ray(consulta)
	if not golpe.is_empty() and not (golpe.collider is Terreno or golpe.collider is TerrenoSalbruma):
		return &"paso_roca"
	return &"paso_arena" if global_position.y < altura_de_arena else &"paso_pasto"


# Fracción del camino a recorrer en este paso para acercarse suavemente a un valor.
func _hacia(rapidez: float, delta: float) -> float:
	return 1.0 - exp(-rapidez * delta)
