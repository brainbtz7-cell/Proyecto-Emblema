class_name CriaturaDePrueba
extends CharacterBody3D
## Criatura que pasea cerca de su punto de aparición y puede iniciar un combate.

@export_group("Combate de prueba")
@export var nombre_de_combate := "Uscita"
@export_range(1, 100) var vida_de_combate := 13
@export_range(1, 10) var dano_de_combate := 4
@export var estilo_de_combate: ManiobrasDeCombate.Estilo = ManiobrasDeCombate.Estilo.USCITA
## Si vale cero, el combate no tiene tope de turnos.
@export_range(0, 15) var limite_de_turnos := 0
## Con nivel 0 es neutral. Si tiene nivel, ataca al detectar a un protagonista de nivel igual o menor.
@export var nivel_hostil := 0
## Clave opcional para los encargos que cuentan derrotas.
@export var derrota_que_cuenta: StringName
## Para oponentes de un encargo que se cuentan una sola vez.
@export var clave_de_derrota_unica: StringName

@export_group("Fauna Anómala")
## Lo decide la manada al hacerlo aparecer (ver nucleo/fauna_anomala.gd).
@export var anomala := false
## Cuánto se desplaza el tono de sus colores si es Anómalo (0 a 1).
@export_range(0.0, 1.0) var tono_anomalo := 0.5
## Rasgo físico extra si es Anómalo. Vacío: cristales provisionales en el lomo.
@export var rasgo_anomalo: PackedScene

@export_group("Paseo")
## Velocidad al caminar, en metros por segundo.
@export var velocidad := 1.5
## Hasta qué distancia de su punto de aparición se aleja.
@export var radio_de_paseo := 7.0
## Segundos que se queda quieto entre un paseo y otro.
@export var pausa_minima := 1.5
@export var pausa_maxima := 5.0
## No se mete donde el suelo esté por debajo de esta altura (agua honda).
@export var altura_minima := -0.3
## Clave de lo que entrega al ser cazado. Solo lo entrega si un encargo
## activo lo pide: es un objeto de misión.
@export var objeto_de_encargo: StringName
## Efecto que aparece en su lugar al ser cazado.
@export var efecto_al_ser_cazado: PackedScene

var _hogar := Vector3.ZERO
var _destino := Vector3.ZERO
var _pausa := 0.0
var _tiempo_atascado := 0.0
var _fase_de_paso := 0.0
var _en_combate := false
var _puede_atacar := true
var _patas: Array[Node] = []

@onready var _modelo: Node3D = $Modelo
@onready var _zona: Interactuable = get_node_or_null("Interactuable")
@onready var _deteccion: Area3D = get_node_or_null("Deteccion")


func _ready() -> void:
	_hogar = global_position
	_destino = _hogar
	_pausa = randf_range(0.0, pausa_maxima)
	_patas = _modelo.find_children("Pata*", "Node3D", false, false)
	if _zona:
		_zona.usado.connect(entrar_en_combate)
	if anomala:
		nombre_de_combate = "%s Anómalo" % nombre_de_combate
		RasgoAnomalo.aplicar(_modelo, tono_anomalo, rasgo_anomalo)


func _physics_process(delta: float) -> void:
	if _en_combate:
		return
	if _deteccion and nivel_hostil > 0:
		_buscar_rival()
		if _en_combate:
			return
	if not is_on_floor():
		velocity.y -= 25.0 * delta

	var marcha := Vector3.ZERO
	if _pausa > 0.0:
		_pausa -= delta
	else:
		var hacia := _destino - global_position
		hacia.y = 0.0
		if global_position.y < altura_minima and _destino != _hogar:
			# Se metió en agua honda: da la vuelta.
			_destino = _hogar
		elif hacia.length() < 0.5 or _tiempo_atascado > 1.0:
			_descansar()
		else:
			marcha = hacia.normalized() * velocidad

	velocity.x = move_toward(velocity.x, marcha.x, 6.0 * delta)
	velocity.z = move_toward(velocity.z, marcha.z, 6.0 * delta)
	move_and_slide()

	# Si quiere caminar y casi no avanza, es que algo le cierra el paso.
	if marcha != Vector3.ZERO and get_real_velocity().length() < velocidad * 0.3:
		_tiempo_atascado += delta
	else:
		_tiempo_atascado = 0.0

	_animar(delta)


# Se detiene un rato y elige el próximo lugar al que caminar.
func _descansar() -> void:
	_pausa = randf_range(pausa_minima, pausa_maxima)
	_tiempo_atascado = 0.0
	var angulo := randf() * TAU
	var distancia := sqrt(randf()) * radio_de_paseo
	_destino = _hogar + Vector3(cos(angulo), 0.0, sin(angulo)) * distancia


func _animar(delta: float) -> void:
	var rapidez := Vector2(velocity.x, velocity.z).length() / maxf(velocidad, 0.01)
	if rapidez > 0.15:
		var angulo := atan2(-velocity.x, -velocity.z)
		_modelo.global_rotation.y = lerp_angle(_modelo.global_rotation.y, angulo, 1.0 - exp(-6.0 * delta))
		_fase_de_paso += delta * 8.0 * rapidez
	# Las patas se mueven en diagonal: delantera izquierda con trasera derecha.
	var balanceo := sin(_fase_de_paso) * 0.5 * clampf(rapidez, 0.0, 1.0)
	for i in _patas.size():
		(_patas[i] as Node3D).rotation.x = balanceo if i % 3 == 0 else -balanceo


# Después de una huida o derrota, el asaltante espera a que el jugador salga de su alcance.
func _buscar_rival() -> void:
	var cuerpos := _deteccion.get_overlapping_bodies()
	if cuerpos.is_empty():
		_puede_atacar = true
		return
	if not _puede_atacar:
		return
	for cuerpo in cuerpos:
		var jugador := cuerpo as Jugador
		if jugador and nivel_hostil >= jugador.nivel_de_prueba:
			_puede_atacar = false
			if not Interfaz.ocupada():
				entrar_en_combate(jugador)
			return


func entrar_en_combate(jugador: Jugador) -> void:
	if _en_combate or Interfaz.ocupada():
		return
	_en_combate = true
	velocity = Vector3.ZERO
	var rival := jugador.global_position - global_position
	_modelo.global_rotation.y = atan2(-rival.x, -rival.z)
	_animar(0.0)
	jugador.encarar(global_position)
	jugador.camara.encuadrar_combate(self)
	Interfaz.combate.iniciar(
		jugador.modelo, _modelo, nombre_de_combate, vida_de_combate, dano_de_combate,
		estilo_de_combate, limite_de_turnos
	)
	var victoria: bool = await Interfaz.combate.terminado
	if is_instance_valid(jugador):
		jugador.camara.restaurar_exploracion()
	_en_combate = false
	if not victoria:
		return
	if anomala:
		var especie := nombre_de_combate.trim_suffix(" Anómalo")
		FaunaAnomala.registrar_caza(especie)
		AvisoAnomalo.mostrar(get_tree(), especie)
	if derrota_que_cuenta != &"":
		Encargos.contar(derrota_que_cuenta, clave_de_derrota_unica)
	if objeto_de_encargo != &"" and Encargos.hace_falta(objeto_de_encargo):
		Encargos.contar(objeto_de_encargo)
	if efecto_al_ser_cazado:
		var efecto := efecto_al_ser_cazado.instantiate() as Node3D
		get_parent().add_child(efecto)
		efecto.global_position = global_position + Vector3.UP * 0.6
	queue_free()
