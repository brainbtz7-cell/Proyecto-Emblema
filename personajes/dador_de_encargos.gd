class_name DadorDeEncargos
extends StaticBody3D
## Personaje que ofrece encargos, uno tras otro, y recibe su entrega.
##
## Muestra un globo con un signo de exclamación cuando tiene algo que decir:
## un encargo para ofrecer o uno cumplido para recibir.

## Nombre que aparece en la caja de diálogo.
@export var nombre := "Aldeano"
@export var girar_al_hablar := true
## Encargos que ofrece, en orden. No ofrece el siguiente hasta completar el anterior.
@export var encargos: Array[Encargo] = []

var _altura_del_globo := 0.0
var _tiempo := 0.0

@onready var _modelo: Node3D = $Modelo
@onready var _globo: Sprite3D = $Globo
@onready var _zona: Interactuable = $Interactuable


func _ready() -> void:
	_altura_del_globo = _globo.position.y
	if _zona.accion == "Hablar":
		_zona.accion = "Hablar · " + nombre
	_zona.usado.connect(_al_hablar)
	Encargos.cambiado.connect(_actualizar)
	_actualizar()
	_apoyar_en_el_suelo()


func _process(delta: float) -> void:
	_tiempo += delta
	_globo.position.y = _altura_del_globo + sin(_tiempo * 3.0) * 0.06


# El primer encargo sin entregar, si ya se puede ofrecer o está en curso.
func _encargo_actual() -> Encargo:
	for encargo in encargos:
		var estado := Encargos.estado_de(encargo)
		if estado == Encargos.Estado.COMPLETADO:
			continue
		if estado == Encargos.Estado.DISPONIBLE and not Encargos.puede_aceptar(encargo):
			return null
		return encargo
	return null


func _actualizar() -> void:
	var encargo := _encargo_actual()
	_zona.disponible = visible and encargo != null
	_globo.visible = _zona.disponible and Encargos.estado_de(encargo) != Encargos.Estado.ACTIVO


func establecer_presencia(presente: bool) -> void:
	if visible == presente:
		return
	visible = presente
	set_deferred("collision_layer", 1 if presente else 0)
	_actualizar()


func _al_hablar(jugador: Jugador) -> void:
	var encargo := _encargo_actual()
	if encargo == null:
		return
	if girar_al_hablar:
		_mirar_a(jugador.global_position)

	var dialogo := Interfaz.dialogo
	match Encargos.estado_de(encargo):
		Encargos.Estado.DISPONIBLE:
			var eleccion: int = await dialogo.preguntar(nombre, encargo.oferta, ["Aceptar", "Ahora no"], 1)
			if eleccion == 0:
				Encargos.aceptar(encargo)
		Encargos.Estado.ACTIVO:
			await dialogo.decir("", "%s: %d de %d." % [encargo.objetivo, Encargos.avance_de(encargo), encargo.cantidad])
		Encargos.Estado.CUMPLIDO:
			Encargos.entregar(encargo)
			var aviso := "Encargo completado: %s." % encargo.titulo
			if not encargo.cierre.is_empty():
				aviso += "\n" + encargo.cierre
			await dialogo.decir("", aviso)
	dialogo.cerrar()


func _mirar_a(punto: Vector3) -> void:
	var hacia := punto - global_position
	if Vector2(hacia.x, hacia.z).length() > 0.1:
		_modelo.global_rotation.y = atan2(-hacia.x, -hacia.z)


# Lo baja o lo sube hasta tocar el suelo, esté donde esté en la escena.
func _apoyar_en_el_suelo() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var altura := Suelo.altura_en(self, global_position.x, global_position.z, [get_rid()])
	if not is_nan(altura):
		global_position.y = altura
