extends Area3D
## Revela rivales marcados por un encargo. Cada victoria queda ligada a su punto.

@export var encargo: Encargo
@export var escena_del_rival: PackedScene
@export var terreno: Terreno
@export_multiline var revelacion := ""

var _revelado := false
var _rivales: Array[CriaturaDePrueba] = []


func _ready() -> void:
	if encargo and Encargos.estado_de(encargo) == Encargos.Estado.ACTIVO and Encargos.avance_de(encargo) > 0:
		_revelado = true
		_desplegar.call_deferred()


func _physics_process(_delta: float) -> void:
	if _revelado or not encargo or Encargos.estado_de(encargo) != Encargos.Estado.ACTIVO or Interfaz.ocupada():
		return
	for cuerpo in get_overlapping_bodies():
		if cuerpo is Jugador:
			_revelado = true
			_presentar.call_deferred(cuerpo)
			return


func _presentar(jugador: Jugador) -> void:
	_desplegar()
	if not revelacion.is_empty():
		await Interfaz.dialogo.decir("Asaltante Klaimyr", revelacion)
		Interfaz.dialogo.cerrar()
	while Interfaz.ocupada():
		await get_tree().process_frame

	if not is_instance_valid(jugador) or not overlaps_body(jugador):
		return
	var mas_cerca: CriaturaDePrueba
	var distancia := INF
	for rival in _rivales:
		if is_instance_valid(rival):
			var separacion := jugador.global_position.distance_squared_to(rival.global_position)
			if separacion < distancia:
				distancia = separacion
				mas_cerca = rival
	if mas_cerca:
		mas_cerca.entrar_en_combate(jugador)


func _desplegar() -> void:
	for punto: Marker3D in $Rivales.get_children():
		if Encargos.contado(encargo, punto.name):
			continue
		var rival := escena_del_rival.instantiate() as CriaturaDePrueba
		rival.nivel_hostil = 0
		rival.radio_de_paseo = 0.0
		rival.derrota_que_cuenta = encargo.clave_de_conteo
		rival.clave_de_derrota_unica = punto.name
		_agregar_interaccion(rival)
		var sitio := punto.global_position
		sitio.y = terreno.altura_en(sitio.x, sitio.z) + 0.06
		rival.transform = global_transform.affine_inverse() * Transform3D(punto.global_basis, sitio)
		add_child(rival)
		_rivales.append(rival)


func _agregar_interaccion(rival: CriaturaDePrueba) -> void:
	var zona := Interactuable.new()
	zona.name = "Interactuable"
	zona.accion = "Enfrentar " + rival.nombre_de_combate
	zona.position.y = 0.7
	var forma := CollisionShape3D.new()
	var alcance := SphereShape3D.new()
	alcance.radius = 0.96
	forma.shape = alcance
	zona.add_child(forma)
	rival.add_child(zona)
