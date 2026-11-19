extends Node3D
## Nubes hechas de bloques que derivan lentamente con el viento.
##
## Se crean al empezar el juego, así que no se ven dentro del editor.

## Cantidad de nubes.
@export var cantidad := 10
## Cada semilla reparte las nubes de otra manera.
@export var semilla := 11
## Las nubes se reparten en un cuadrado de este radio, en metros.
@export var radio := 110.0
## Altura base de las nubes, en metros.
@export var altura := 30.0
## Dirección y velocidad del viento, en metros por segundo.
@export var viento := Vector3(0.9, 0.0, 0.35)
## Si proyectan sombra sobre el suelo. Apagado, el terreno se lee más claro.
@export var proyectan_sombra := false
@export var material: Material


func _ready() -> void:
	# Las nubes se mueven en cada cuadro, no en el paso de física.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var caja := BoxMesh.new()
	caja.material = material
	for n in cantidad:
		var nube := Node3D.new()
		nube.position = Vector3(
			azar.randf_range(-radio, radio),
			altura + azar.randf_range(-4.0, 7.0),
			azar.randf_range(-radio, radio))
		for b in azar.randi_range(4, 7):
			var bloque := MeshInstance3D.new()
			bloque.mesh = caja
			if not proyectan_sombra:
				bloque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			bloque.scale = Vector3(azar.randf_range(3.0, 7.0), azar.randf_range(1.2, 2.4), azar.randf_range(3.0, 6.0))
			bloque.position = Vector3(azar.randf_range(-4.5, 4.5), azar.randf_range(-0.6, 0.9), azar.randf_range(-3.0, 3.0))
			nube.add_child(bloque)
		add_child(nube)


func _process(delta: float) -> void:
	for nube: Node3D in get_children():
		nube.position += viento * delta
		# Al salir por un lado, la nube vuelve a entrar por el opuesto.
		nube.position.x = wrapf(nube.position.x, -radio, radio)
		nube.position.z = wrapf(nube.position.z, -radio, radio)
