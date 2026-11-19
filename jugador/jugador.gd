class_name Jugador
extends CharacterBody3D
## El protagonista: se mueve en tercera persona, salta y hace doble salto.
##
## Todos los valores se pueden ajustar en el Inspector sin tocar el código.
## Cómo se ve y cómo se anima lo decide la figura (ver figura.gd).

@export var nivel_de_prueba := 1

@export_group("Movimiento")
## Velocidad máxima al caminar, en metros por segundo.
@export var velocidad := 5.5
## Aumento de velocidad al mantener Correr en tierra firme.
@export_range(1.0, 2.0, 0.01) var ritmo_de_carrera := 1.42
## Fracción de velocidad que conserva al vadear con el agua a la cintura.
@export_range(0.3, 1.0, 0.01) var ritmo_en_agua := 0.58
## Qué tan rápido alcanza la velocidad máxima.
@export var aceleracion := 45.0
## Qué tan rápido se detiene al soltar los controles.
@export var frenado := 55.0
## Cuánto control queda en el aire (0 = ninguno, 1 = igual que en el suelo).
@export_range(0.0, 1.0) var control_en_el_aire := 0.55

@export_group("Salto")
## Altura máxima del salto, en metros.
@export var altura_de_salto := 1.5
## Segundos que tarda en llegar al punto más alto.
@export var tiempo_de_subida := 0.36
## Segundos que tarda en caer desde el punto más alto.
@export var tiempo_de_caida := 0.3
## Margen para saltar justo después de pisar fuera de un borde.
@export var tiempo_coyote := 0.12
## Margen para que cuente un salto pulsado justo antes de aterrizar.
@export var memoria_de_salto := 0.12
## Al soltar el botón antes de tiempo, el salto se acorta a esta fracción.
@export_range(0.0, 1.0) var corte_de_salto := 0.45
@export var velocidad_maxima_de_caida := 22.0

@export_group("Estribos del Risco")
## Permite impulsarse una segunda vez en el aire.
@export var doble_salto := true
## Altura que gana el segundo impulso, en metros.
@export var altura_de_doble_salto := 1.3

@export_group("Caídas")
## Por debajo de esta altura, el protagonista vuelve al último lugar seguro.
@export var altura_minima := -1.1
## Un lugar cuenta como seguro si está al menos esta distancia por encima.
@export var margen_seguro := 0.5

var _coyote := 0.0
var _memoria := 0.0
var _saltos_en_el_aire := 0
var _estaba_en_el_suelo := true
var _ultimo_lugar_seguro := Vector3.ZERO

@onready var modelo: Figura = $Modelo
@onready var camara: Node3D = $Camara
@onready var polvo: CPUParticles3D = $Polvo


func _ready() -> void:
	_ultimo_lugar_seguro = global_position


func _physics_process(delta: float) -> void:
	var en_el_suelo := is_on_floor()

	if en_el_suelo:
		_coyote = tiempo_coyote
		_saltos_en_el_aire = 1 if doble_salto else 0
		if global_position.y > altura_minima + margen_seguro:
			_ultimo_lugar_seguro = global_position
	else:
		_coyote -= delta
		velocity.y = maxf(velocity.y - _gravedad() * delta, -velocidad_maxima_de_caida)

	# Durante un diálogo o combate, el protagonista no responde a los controles.
	var libre := not Interfaz.ocupada()

	_memoria -= delta
	if libre and Input.is_action_just_pressed("saltar"):
		_memoria = memoria_de_salto
	if libre and _memoria > 0.0:
		if _coyote > 0.0:
			_saltar(altura_de_salto)
		elif _saltos_en_el_aire > 0:
			_saltos_en_el_aire -= 1
			_saltar(altura_de_doble_salto)
			modelo.al_doble_salto()
			_levantar_polvo()
	if Input.is_action_just_released("saltar") and velocity.y > 0.0:
		velocity.y *= corte_de_salto

	# El movimiento es relativo a la cámara: "adelante" es hacia donde mira.
	var entrada := Vector2.ZERO
	if libre:
		entrada = Input.get_vector("mover_izquierda", "mover_derecha", "mover_adelante", "mover_atras")
	var direccion := Vector3(entrada.x, 0.0, entrada.y).rotated(Vector3.UP, camara.rotation.y)
	var profundidad := clampf(-global_position.y / 0.90, 0.0, 1.0)
	var impulso := ritmo_de_carrera if libre and Input.is_action_pressed(&"correr") else 1.0
	var velocidad_objetivo := velocidad * lerpf(impulso, ritmo_en_agua, profundidad)
	var cambio := aceleracion if entrada != Vector2.ZERO else frenado
	if not en_el_suelo:
		cambio *= control_en_el_aire
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(direccion * velocidad_objetivo, cambio * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	var velocidad_de_caida := -velocity.y
	move_and_slide()

	if is_on_floor() and not _estaba_en_el_suelo and velocidad_de_caida > 4.0:
		modelo.al_aterrizar()
		_levantar_polvo()
	_estaba_en_el_suelo = is_on_floor()

	if global_position.y < altura_minima:
		teletransportar(_ultimo_lugar_seguro)

	var desplazamiento := get_real_velocity()
	var rapidez := Vector2(desplazamiento.x, desplazamiento.z).length()
	var carrera := clampf((rapidez - velocidad) / maxf(0.01, velocidad * (ritmo_de_carrera - 1.0)), 0.0, 1.0)
	camara.impulso_de_carrera = carrera if libre else 0.0
	modelo.animar(delta, velocity, velocidad, is_on_floor(), direccion, carrera)


## Detiene el desplazamiento y hace que la figura mire al otro combatiente.
func encarar(destino: Vector3) -> void:
	_memoria = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	camara.impulso_de_carrera = 0.0
	var hacia := destino - global_position
	modelo.global_rotation.y = atan2(-hacia.x, -hacia.z)


## Mueve al protagonista de golpe a otro lugar, sin deslizarlo hasta allí.
func teletransportar(destino: Vector3) -> void:
	global_position = destino
	velocity = Vector3.ZERO
	camara.impulso_de_carrera = 0.0
	_ultimo_lugar_seguro = destino
	reset_physics_interpolation()
	camara.centrar()


# La gravedad sale de la altura y los tiempos de salto elegidos. Se cae más
# rápido de lo que se sube: el salto se siente más firme.
func _gravedad() -> float:
	var tiempo := tiempo_de_subida if velocity.y > 0.0 else tiempo_de_caida
	return 2.0 * altura_de_salto / (tiempo * tiempo)


func _saltar(altura: float) -> void:
	var gravedad_de_subida := 2.0 * altura_de_salto / (tiempo_de_subida * tiempo_de_subida)
	velocity.y = sqrt(2.0 * gravedad_de_subida * altura)
	_coyote = 0.0
	_memoria = 0.0
	modelo.al_saltar()


func _levantar_polvo() -> void:
	# El nodo Agua dibuja la salpicadura bajo el nivel de la ribera.
	if global_position.y < 0.0:
		return
	polvo.global_position = global_position + Vector3.UP * 0.1
	polvo.restart()
