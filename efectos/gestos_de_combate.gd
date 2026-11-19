class_name GestosDeCombate
extends Node
## Desplaza solo los modelos durante las acciones. Las colisiones se quedan en su lugar.


func defender(modelo: Node3D) -> void:
	var gesto := create_tween()
	gesto.tween_property(modelo, "rotation:x", -0.26, 0.16).set_trans(Tween.TRANS_QUAD)
	if modelo is Figura:
		gesto.parallel().tween_property(modelo, "guardia_de_combate", 1.30, 0.16)
	await gesto.finished


func alistar(modelo: Node3D, angulo: float, texto: String, color: Color) -> void:
	_mostrar_impacto(modelo.global_position + Vector3.UP * 0.9, texto, color, false)
	var gesto := create_tween()
	gesto.tween_property(modelo, "rotation:x", angulo, 0.29).set_trans(Tween.TRANS_SINE)
	await gesto.finished


func bajar_guardia(modelo: Node3D) -> void:
	modelo.rotation.x = 0.0
	if modelo is Figura:
		modelo.guardia_de_combate = 0.0


func golpear(
	atacante: Node3D, blanco: Node3D, dano: int, defendido: bool, al_impactar: Callable,
	fuerza := 1.0
) -> void:
	var origen := atacante.position
	var reposo_blanco := blanco.position
	var inclinacion := blanco.rotation.x
	var hacia := blanco.global_position - atacante.global_position
	hacia.y = 0.0
	var direccion := hacia.normalized()
	var impulso := minf(hacia.length() * 0.53, 0.78 * fuerza)
	var paso := (atacante.get_parent() as Node3D).global_basis.inverse() * direccion
	var paso_blanco := (blanco.get_parent() as Node3D).global_basis.inverse() * direccion
	var golpe := create_tween()
	var espera := 0.16 * fuerza
	golpe.tween_property(atacante, "position", origen - paso * 0.16 * fuerza, espera).set_trans(Tween.TRANS_SINE)
	golpe.parallel().tween_property(atacante, "rotation:x", -0.20 * fuerza, espera)
	if atacante is Figura:
		golpe.parallel().tween_property(atacante, "golpe_de_combate", -0.55 * fuerza, espera)
	golpe.tween_property(atacante, "position", origen + paso * impulso, 0.11).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	golpe.parallel().tween_property(atacante, "rotation:x", 0.24 * fuerza, 0.11)
	if atacante is Figura:
		golpe.parallel().tween_property(atacante, "golpe_de_combate", 1.60, 0.11)
	await golpe.finished
	al_impactar.call()

	var texto := "Esquiva"
	var color := Color(0.76, 0.89, 1.0)
	var retroceso := 0.38
	if dano > 0 and defendido:
		texto = "Bloqueo  −%d" % dano
		color = Color(0.57, 0.96, 1.0)
		retroceso = 0.18
	elif dano > 0:
		texto = "−%d" % dano
		color = Color(1.0, 0.78, 0.4)
		retroceso = 0.27 * fuerza
	_mostrar_impacto(blanco.global_position + Vector3.UP * 0.9, texto, color, dano > 0, fuerza)

	var reaccion := create_tween().set_parallel(true)
	reaccion.tween_property(blanco, "position", reposo_blanco + paso_blanco * retroceso, 0.09)
	reaccion.tween_property(blanco, "rotation:x", inclinacion - 0.35, 0.09)
	reaccion.tween_property(atacante, "position", origen, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reaccion.tween_property(atacante, "rotation:x", 0.0, 0.25)
	if atacante is Figura:
		reaccion.tween_property(atacante, "golpe_de_combate", 0.0, 0.25)
	reaccion.chain().tween_property(blanco, "position", reposo_blanco, 0.18).set_trans(Tween.TRANS_SINE)
	reaccion.parallel().tween_property(blanco, "rotation:x", 0.0, 0.18)
	if blanco is Figura and defendido:
		reaccion.parallel().tween_property(blanco, "guardia_de_combate", 0.0, 0.18)
	await reaccion.finished


func caer(modelo: Node3D) -> void:
	var gesto := create_tween().set_parallel(true)
	gesto.tween_property(modelo, "rotation:z", 0.7, 0.30).set_trans(Tween.TRANS_CUBIC)
	gesto.tween_property(modelo, "position:y", modelo.position.y - 0.27, 0.30)
	await gesto.finished


func _mostrar_impacto(punto: Vector3, texto: String, color: Color, acierto: bool, fuerza := 1.0) -> void:
	var numero := Label3D.new()
	numero.text = texto
	numero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	numero.pixel_size = 0.007
	numero.font_size = 36
	numero.outline_size = 8
	numero.modulate = color
	numero.no_depth_test = true
	add_child(numero)
	numero.global_position = punto + Vector3.UP * 0.48
	var salida := numero.create_tween().set_parallel(true)
	salida.tween_property(numero, "global_position:y", numero.global_position.y + 0.54, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	salida.tween_property(numero, "modulate:a", 0.0, 0.25).set_delay(0.47)
	salida.tween_property(numero, "outline_modulate:a", 0.0, 0.25).set_delay(0.47)
	salida.chain().tween_callback(numero.queue_free)

	if not acierto:
		return
	var chispas := CPUParticles3D.new()
	chispas.amount = roundi(14.0 * fuerza)
	chispas.one_shot = true
	chispas.emitting = false
	chispas.explosiveness = 1.0
	chispas.lifetime = 0.35
	chispas.spread = 180.0
	chispas.initial_velocity_min = 1.3
	chispas.initial_velocity_max = 3.2
	chispas.gravity = Vector3(0.0, -4.0, 0.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	var cubo := BoxMesh.new()
	cubo.size = Vector3(0.075, 0.075, 0.075)
	cubo.material = material
	chispas.mesh = cubo
	add_child(chispas)
	chispas.global_position = punto
	chispas.finished.connect(chispas.queue_free)
	chispas.emitting = true
