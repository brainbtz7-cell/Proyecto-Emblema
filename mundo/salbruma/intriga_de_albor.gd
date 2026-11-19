extends Node3D
## Investigación de Puerto Albor (Documento Maestro, 9.3 y 9.7): Dudas
## razonables, El testigo silenciado, Echa luz sobre tanta oscuridad y El rostro
## del engaño. Al derrotar al profeta se cierra la misión dorada y La Voz da la
## siguiente.
##
## PROVISIONAL: los diálogos, las figuras (todas con el modelo de aldeano), el
## patio del líder y la ubicación de cada cosa. El documento deja pendientes los
## diálogos y objetivos internos de estos encargos, las recompensas, la
## identidad del profeta y la explicación de su desaparición.
## Los elementos únicos de Encargos permiten reconstruir cada etapa al continuar.

const DUDAS := preload("res://encargos/puerto_albor_dudas_razonables.tres")
const TESTIGO := preload("res://encargos/puerto_albor_testigo_silenciado.tres")
const LUZ := preload("res://encargos/puerto_albor_echa_luz.tres")
const ROSTRO := preload("res://encargos/puerto_albor_rostro_del_engano.tres")
const IMPOSTOR := preload("res://encargos/la_voz_desenmascara_al_impostor.tres")
const MONTANA := preload("res://encargos/la_voz_misterios_de_la_montana.tres")
const ALDEANO := preload("res://personajes/aldeano.tscn")
const TABLON := preload("res://personajes/tablon_de_junco.tscn")
const PERSONAJE := preload("res://personajes/personaje_de_intriga.gd")
const POLVO := preload("res://efectos/polvo.tscn")
const TOON := preload("res://shaders/toon.gdshader")
## Centro y medio tamaño del patio del líder, al oeste del pueblo (provisional).
const PATIO := Vector2(55, -164)
const MEDIO_PATIO := Vector2(6.5, 6.0)
## Ancho del portón que da al pueblo.
const ANCHO_DEL_PORTON := 4.0
## Altura de los muros sobre el punto más alto del suelo que pisan. Supera el
## doble salto (2,9 m) para que no se pueda entrar saltando.
const ALTO_DEL_MURO := 3.4
## Distancia a la que el acompañante deja de seguir los pasos y se acerca de golpe.
const DISTANCIA_DE_REUNION := 12.0
const TESTIMONIOS := [
	"El profeta culpa a Puerto Junco de nuestros problemas. Nadie mostró pruebas.",
	"El vecino que duda de él conserva amigos en Junco. Quiere que lo escuchen.",
	"El profeta insiste en que desconfiemos de los forasteros.",
]

var _vecino: HabitanteDeIntriga
var _lider: HabitanteDeIntriga
var _cuerpo: HabitanteDeIntriga
var _nota: HabitanteDeIntriga
var _jefe: HabitanteDeIntriga
var _bloqueadores: Array[HabitanteDeIntriga] = []
var _conversaciones: Array[Interactuable] = []
var _habitantes: Array[DadorDeEncargos] = []
var _paso: StaticBody3D
var _sicario: CriaturaDePrueba
var _profeta: CriaturaDePrueba
var _tramitando := false
var _resolviendo := false
var _acompanaba := false
var _huellas: Array[Vector3] = []
var _ultima_huella := Vector3.ZERO

@onready var _mundo: Node3D = get_parent()
@onready var _jugador: Jugador = _mundo.get_node("Jugador")
@onready var _terreno: Terreno = _mundo.get_node("Terreno")


func _ready() -> void:
	_vecino = _persona("HabitanteDesconfiado", "Habitante desconfiado", Vector2(80, -164))
	_lider = _persona("LiderAlbor", "Líder de Puerto Albor", PATIO + Vector2(-1.5, 2.0))
	# La víctima es el mismo habitante desconfiado, tendido junto a la orilla.
	_cuerpo = _persona("Testigo", "Habitante desconfiado", Vector2(115, -190), "Examinar el cuerpo", false)
	_sin_cuerpo(_cuerpo)
	_cuerpo.get_node("Modelo").rotation.z = PI * 0.5
	_cuerpo.get_node("Modelo").position.y = 0.32
	_nota = _persona("Nota", "Nota", Vector2(113, -191), "Leer la nota", false)
	_sin_cuerpo(_nota)
	_nota.get_node("Modelo").hide()
	_nota.add_child(_papel())
	_jefe = _persona("JefeAcompanante", "Jefe pesquero", Vector2(74, 29))
	_sin_cuerpo(_jefe)

	var tablero := TABLON.instantiate() as DadorDeEncargos
	tablero.name = "TablonAlbor"
	tablero.encargos.assign([TESTIGO, LUZ])
	add_child(tablero)
	tablero.position = _suelo(Vector2(87, -164))
	# Echa luz aparece también en el tablón de Puerto Junco.
	var tablon_junco := _mundo.get_node("Tablon") as DadorDeEncargos
	if not tablon_junco.encargos.has(LUZ):
		tablon_junco.encargos.append(LUZ)
		tablon_junco._actualizar()

	for nombre: String in ["HabitanteDeAlbor", "Barquero", "Pescadora"]:
		var habitante := _mundo.get_node(nombre) as DadorDeEncargos
		_habitantes.append(habitante)
		_conversaciones.append(_interaccion(habitante, "Conversacion", "Investigar al profeta", _testimonio.bind(_habitantes.size() - 1)))
	var jefe_original := _mundo.get_node("JefePesquero") as DadorDeEncargos
	_interaccion(jefe_original, "NotaDeAlbor", "Mostrar la nota al jefe", _mostrar_nota)

	_construir_patio()
	# Los tres habitantes se plantan frente al portón del patio.
	for i in 3:
		var sitio := Vector2(PATIO.x + MEDIO_PATIO.x + 1.9, PATIO.y + 1.6 * (i - 1))
		_bloqueadores.append(_persona("Entrada%d" % i, "Habitante de la entrada", sitio))
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func _actualizar() -> void:
	var dudas_listas := Encargos.estado_de(DUDAS) == Encargos.Estado.CUMPLIDO
	_vecino.habilitar(Encargos.puede_aceptar(DUDAS) or _activo(DUDAS) or dudas_listas, _hablar_vecino)
	# El globo avisa solo cuando hay algo para ofrecer o recibir.
	_vecino.get_node("Globo").visible = _vecino.visible and not _activo(DUDAS)
	var abierto := Encargos.estado_de(LUZ) == Encargos.Estado.COMPLETADO
	_lider.habilitar(abierto and Encargos.estado_de(ROSTRO) != Encargos.Estado.CUMPLIDO, _hablar_lider, true)
	_lider.get_node("Globo").visible = abierto and Encargos.puede_aceptar(ROSTRO)
	_cuerpo.habilitar(_activo(TESTIGO), _investigar_cuerpo)
	_cuerpo.get_node("Globo").visible = _cuerpo.visible and not _contado(TESTIGO, &"cuerpo")
	_nota.habilitar(_activo(TESTIGO) and _contado(TESTIGO, &"sicario") and not _contado(TESTIGO, &"nota"), _leer_nota)

	# El jefe pesquero acompaña desde que ve la nota hasta que cae el profeta.
	var mostrar_jefe := _contado(LUZ, &"jefe") and Encargos.estado_de(ROSTRO) != Encargos.Estado.COMPLETADO
	if mostrar_jefe and not _acompanaba:
		_reunir_al_jefe()
	_acompanaba = mostrar_jefe
	_jefe.habilitar(false, Callable(), mostrar_jefe)
	var jefe_original := _mundo.get_node("JefePesquero") as DadorDeEncargos
	if Encargos.estado_de(TESTIGO) != Encargos.Estado.DISPONIBLE:
		jefe_original.establecer_presencia(not mostrar_jefe)
	var zona_nota := jefe_original.get_node("NotaDeAlbor") as Interactuable
	zona_nota.disponible = _activo(LUZ) and not _contado(LUZ, &"jefe")
	if zona_nota.disponible:
		jefe_original.get_node("Interactuable").disponible = false
		jefe_original.get_node("Globo").show()

	for i in _conversaciones.size():
		var investigar := _activo(DUDAS)
		_conversaciones[i].disponible = investigar
		if investigar:
			_habitantes[i].get_node("Interactuable").disponible = false
			_habitantes[i].get_node("Globo").visible = not _contado(DUDAS, _clave_habitante(i))
	# Quedan frente al portón mientras dura Echa luz; se convence a cada uno una vez.
	for i in _bloqueadores.size():
		_bloqueadores[i].habilitar(_activo(LUZ) and not _contado(LUZ, _clave_habitante(i)), _convencer.bind(i), _activo(LUZ))
	_paso.visible = not abierto
	_paso.get_node("Colision").set_deferred("disabled", abierto)
	_actualizar_rivales()
	if Encargos.estado_de(ROSTRO) >= Encargos.Estado.CUMPLIDO and Encargos.estado_de(MONTANA) == Encargos.Estado.DISPONIBLE:
		_finalizar.call_deferred()


func _physics_process(delta: float) -> void:
	if _jefe.visible:
		_seguir(delta)
	if Interfaz.ocupada() or _tramitando or not _activo(TESTIGO) or not _contado(TESTIGO, &"nota"):
		return
	var posicion := Vector2(_jugador.global_position.x, _jugador.global_position.z)
	if not _contado(TESTIGO, &"acusacion") and posicion.distance_to(TrazadoSalbruma.PUERTO_ALBOR) < 16.0:
		_acusar.call_deferred()
	elif _contado(TESTIGO, &"acusacion") and posicion.distance_to(TrazadoSalbruma.PUERTO) < 18.0:
		Encargos.contar(TESTIGO.clave_de_conteo, &"junco")
		Encargos.entregar(TESTIGO)


func _hablar_vecino(_quien: Jugador) -> void:
	await _ofrecer(_vecino.nombre, DUDAS, "Lo que te contaron confirma mis sospechas. Gracias por escucharlos.")


func _hablar_lider(_quien: Jugador) -> void:
	await _ofrecer(_lider.nombre, ROSTRO, "", "Gracias. Albor y Puerto Junco pueden volver a comerciar.")


func _ofrecer(nombre: String, encargo: Encargo, al_cumplir: String, al_terminar := "") -> void:
	match Encargos.estado_de(encargo):
		Encargos.Estado.DISPONIBLE:
			if Encargos.puede_aceptar(encargo):
				var opcion: int = await Interfaz.dialogo.preguntar(nombre, encargo.oferta, ["Aceptar", "Ahora no"], 1)
				if opcion == 0:
					Encargos.aceptar(encargo)
		Encargos.Estado.CUMPLIDO:
			await Interfaz.dialogo.decir(nombre, al_cumplir)
			Encargos.entregar(encargo)
		Encargos.Estado.COMPLETADO:
			if not al_terminar.is_empty():
				await Interfaz.dialogo.decir(nombre, al_terminar)
		_:
			await Interfaz.dialogo.decir(nombre, encargo.indicacion)
	Interfaz.dialogo.cerrar()


func _testimonio(_quien: Jugador, indice: int) -> void:
	await Interfaz.dialogo.decir(_habitantes[indice].nombre, TESTIMONIOS[indice])
	Encargos.contar(DUDAS.clave_de_conteo, _clave_habitante(indice))
	Interfaz.dialogo.cerrar()


func _investigar_cuerpo(_quien: Jugador) -> void:
	var texto := "Es el habitante que te pidió investigar al profeta. Lo asesinaron."
	if _contado(TESTIGO, &"sicario"):
		texto = "Hay una nota junto al cuerpo." if not _contado(TESTIGO, &"nota") else "Ya tenés la nota. Volvé a Albor."
	await Interfaz.dialogo.decir("", texto)
	Encargos.contar(TESTIGO.clave_de_conteo, &"cuerpo")
	Interfaz.dialogo.cerrar()


func _leer_nota(_quien: Jugador) -> void:
	await Interfaz.dialogo.decir("Nota del habitante", "Temo por mi vida. Le pedí a un forastero que investigara al profeta y lo desenmascarara.")
	Encargos.contar(TESTIGO.clave_de_conteo, &"nota")
	Interfaz.dialogo.cerrar()


func _acusar() -> void:
	if _tramitando:
		return
	_tramitando = true
	await Interfaz.dialogo.decir("Habitante de Albor", "El profeta te acusa de haber asesinado al vecino. ¡Tenés que irte!")
	Encargos.contar(TESTIGO.clave_de_conteo, &"acusacion")
	Interfaz.dialogo.cerrar()
	_tramitando = false


func _mostrar_nota(_quien: Jugador) -> void:
	await Interfaz.dialogo.decir("Jefe pesquero", "Era mi amigo; reconozco su letra. Voy con vos a Albor: les mostraremos la nota a quienes bloquean el paso.")
	Encargos.contar(LUZ.clave_de_conteo, &"jefe")
	Interfaz.dialogo.cerrar()


func _convencer(_quien: Jugador, indice: int) -> void:
	if not _contado(LUZ, &"jefe"):
		await Interfaz.dialogo.decir("Habitante de la entrada", "El profeta dice que mataste al vecino. No vas a pasar.")
	else:
		await Interfaz.dialogo.decir("Habitante de la entrada", "Si el jefe pesquero de Junco responde por vos y la nota es de su amigo... Está bien, te creo.")
		Encargos.contar(LUZ.clave_de_conteo, _clave_habitante(indice))
		if Encargos.estado_de(LUZ) == Encargos.Estado.CUMPLIDO:
			Encargos.entregar(LUZ)
	Interfaz.dialogo.cerrar()


func _enfrentar_sicario(quien: Jugador) -> void:
	await Interfaz.dialogo.decir("Sicario", "El profeta me envió. También tengo que silenciarte.")
	Interfaz.dialogo.cerrar()
	while Interfaz.ocupada():
		await get_tree().process_frame
	if is_instance_valid(_sicario):
		_sicario.entrar_en_combate(quien)


func _confrontar(quien: Jugador) -> void:
	await Interfaz.dialogo.decir("Profeta", "La nota, el jefe pesquero, los testigos... ¡No vas a seguir hablando!")
	Interfaz.dialogo.cerrar()
	while Interfaz.ocupada():
		await get_tree().process_frame
	if is_instance_valid(_profeta):
		_profeta.entrar_en_combate(quien)


func _actualizar_rivales() -> void:
	if _activo(TESTIGO) and _contado(TESTIGO, &"cuerpo") and not _contado(TESTIGO, &"sicario") and not is_instance_valid(_sicario):
		_sicario = _rival("Sicario", Vector2(115.5, -187), TESTIGO, &"sicario", 16, 4)
		var zona_sicario := _sicario.get_node("Interactuable") as Interactuable
		zona_sicario.usado.disconnect(_sicario.entrar_en_combate)
		zona_sicario.usado.connect(_enfrentar_sicario)
	if _activo(ROSTRO) and not is_instance_valid(_profeta):
		_profeta = _rival("Profeta", PATIO + Vector2(-3.0, -2.0), ROSTRO, &"profeta", 22, 5)
		_profeta.limite_de_turnos = 15
		_profeta.estilo_de_combate = ManiobrasDeCombate.Estilo.CAPITAN
		var zona := _profeta.get_node("Interactuable") as Interactuable
		zona.usado.disconnect(_profeta.entrar_en_combate)
		zona.usado.connect(_confrontar)


func _finalizar() -> void:
	if _resolviendo:
		return
	_resolviendo = true
	while Interfaz.ocupada():
		await get_tree().process_frame
	Encargos.entregar(ROSTRO)
	if Encargos.estado_de(IMPOSTOR) == Encargos.Estado.ACTIVO:
		Encargos.contar(IMPOSTOR.clave_de_conteo, &"profeta")
		Encargos.entregar(IMPOSTOR)
		if not IMPOSTOR.cierre.is_empty():
			await Interfaz.dialogo.decir("", IMPOSTOR.cierre)
	# Visión de La Voz (9.3, punto 7) y siguiente misión dorada (9.4).
	if Encargos.puede_aceptar(MONTANA):
		await Interfaz.dialogo.decir("La Voz", MONTANA.oferta)
		Encargos.aceptar(MONTANA)
	Interfaz.dialogo.cerrar()
	_resolviendo = false


# Sigue el rastro de pasos del protagonista, unos metros por detrás.
func _seguir(delta: float) -> void:
	var posicion := _jugador.global_position
	if posicion.distance_to(_ultima_huella) > 7.0 or posicion.distance_to(_jefe.global_position) > DISTANCIA_DE_REUNION:
		_reunir_al_jefe()
		return
	if posicion.distance_to(_ultima_huella) > 0.45:
		_huellas.append(posicion)
		_ultima_huella = posicion
	if _huellas.size() > 4:
		var hacia := _huellas[0] - _jefe.global_position
		_jefe.get_node("Modelo").rotation.y = atan2(-hacia.x, -hacia.z)
		# Apura el paso cuando se queda atrás.
		var rapidez := 6.85 + 0.35 * (_huellas.size() - 4)
		_jefe.global_position = _jefe.global_position.move_toward(_huellas[0], rapidez * delta)
		if hacia.length() < 0.18:
			_huellas.pop_front()


func _reunir_al_jefe() -> void:
	_jefe.global_position = _jugador.global_position + Vector3(1.2, 0, 1.2)
	_ultima_huella = _jugador.global_position
	_huellas.clear()


func _persona(id: String, nombre: String, sitio: Vector2, accion := "", con_rotulo := true) -> HabitanteDeIntriga:
	var base := ALDEANO.instantiate()
	base.set_script(PERSONAJE)
	var actor := base as HabitanteDeIntriga
	actor.name = id
	actor.nombre = nombre
	add_child(actor)
	actor.position = _suelo(sitio)
	if not accion.is_empty():
		(actor.get_node("Interactuable") as Interactuable).accion = accion
	if con_rotulo:
		# Igual que los rótulos de los demás habitantes de la escena.
		var rotulo := Label3D.new()
		rotulo.name = "Rotulo"
		rotulo.text = nombre
		rotulo.position.y = 2.47
		rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rotulo.font_size = 28
		rotulo.outline_size = 8
		rotulo.pixel_size = 0.005
		rotulo.visibility_range_end = 15.0
		actor.add_child(rotulo)
	return actor


# Ni frena al protagonista ni a la cámara, ni gira al hablarle.
func _sin_cuerpo(actor: HabitanteDeIntriga) -> void:
	actor.solido = false
	actor.collision_layer = 0
	actor.girar_al_hablar = false


func _papel() -> MeshInstance3D:
	var papel := MeshInstance3D.new()
	var hoja := BoxMesh.new()
	hoja.size = Vector3(0.34, 0.02, 0.44)
	papel.mesh = hoja
	papel.position.y = 0.08
	papel.rotation.y = 0.4
	papel.material_override = _material(Color("e9dfc4"))
	return papel


func _rival(nombre: String, sitio: Vector2, encargo: Encargo, clave: StringName, vida: int, dano: int) -> CriaturaDePrueba:
	var rival := CriaturaDePrueba.new()
	rival.name = nombre
	rival.nombre_de_combate = nombre
	rival.vida_de_combate = vida
	rival.dano_de_combate = dano
	rival.estilo_de_combate = ManiobrasDeCombate.Estilo.ASALTANTE
	rival.derrota_que_cuenta = encargo.clave_de_conteo
	rival.clave_de_derrota_unica = clave
	rival.radio_de_paseo = 0.0
	rival.collision_layer = 8
	rival.collision_mask = 1
	rival.efecto_al_ser_cazado = POLVO
	var referencia := ALDEANO.instantiate()
	var modelo := referencia.get_node("Modelo").duplicate() as Node3D
	rival.add_child(modelo)
	referencia.free()
	var colision := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.height = 1.5
	capsula.radius = 0.3
	colision.shape = capsula
	colision.position.y = 0.75
	rival.add_child(colision)
	_interaccion(rival, "Interactuable", "Enfrentar al " + nombre.to_lower(), Callable())
	add_child(rival)
	rival.position = _suelo(sitio)
	return rival


func _interaccion(padre: Node3D, nombre: String, accion: String, usado: Callable) -> Interactuable:
	var zona := Interactuable.new()
	zona.name = nombre
	zona.accion = accion
	zona.position.y = 0.7
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.0
	forma.shape = esfera
	zona.add_child(forma)
	if usado.is_valid():
		zona.usado.connect(usado)
	padre.add_child(zona)
	return zona


# Patio cerrado del líder con un portón hacia el pueblo. El portón ("PasoAlLider")
# desaparece al completar Echa luz sobre tanta oscuridad.
func _construir_patio() -> void:
	var oeste := PATIO.x - MEDIO_PATIO.x
	var este := PATIO.x + MEDIO_PATIO.x
	var norte := PATIO.y - MEDIO_PATIO.y
	var sur := PATIO.y + MEDIO_PATIO.y
	var porton := ANCHO_DEL_PORTON * 0.5
	# Los mismos colores que las casas de Albor: muro marfil con remate de teja.
	var marfil := Color("d5bd91")
	_pared("MuroNorte", Vector2(oeste, norte), Vector2(este, norte), marfil)
	_pared("MuroSur", Vector2(oeste, sur), Vector2(este, sur), marfil)
	_pared("MuroOeste", Vector2(oeste, norte), Vector2(oeste, sur), marfil)
	_pared("MuroEsteNorte", Vector2(este, norte), Vector2(este, PATIO.y - porton), marfil)
	_pared("MuroEsteSur", Vector2(este, PATIO.y + porton), Vector2(este, sur), marfil)
	_paso = _pared("PasoAlLider", Vector2(este, PATIO.y - porton), Vector2(este, PATIO.y + porton), Color("785743"), 0.4, false)


# Muro de "desde" a "hasta" que sigue la pendiente: se hunde bajo el punto más bajo
# y termina horizontal a ALTO_DEL_MURO sobre el más alto.
func _pared(nombre: String, desde: Vector2, hasta: Vector2, color: Color, grosor := 0.7, con_remate := true) -> StaticBody3D:
	var bajo := INF
	var alto := -INF
	for i in 9:
		var punto := desde.lerp(hasta, i / 8.0)
		var altura := _terreno.altura_en(punto.x, punto.y)
		bajo = minf(bajo, altura)
		alto = maxf(alto, altura)
	var base := bajo - 0.4
	var cima := alto + ALTO_DEL_MURO
	var tamano := Vector3(grosor, cima - base, desde.distance_to(hasta) + grosor)
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	var forma := CollisionShape3D.new()
	forma.name = "Colision"
	var caja := BoxShape3D.new()
	caja.size = tamano
	forma.shape = caja
	cuerpo.add_child(forma)
	var vista := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = tamano
	vista.mesh = malla
	vista.material_override = _material(color)
	cuerpo.add_child(vista)
	if con_remate:
		var remate := MeshInstance3D.new()
		var teja := BoxMesh.new()
		teja.size = Vector3(grosor + 0.24, 0.24, tamano.z + 0.24)
		remate.mesh = teja
		remate.position.y = tamano.y * 0.5 + 0.12
		remate.material_override = _material(Color("9d5542"))
		cuerpo.add_child(remate)
	add_child(cuerpo)
	var centro := (desde + hasta) * 0.5
	cuerpo.position = Vector3(centro.x, (base + cima) * 0.5, centro.y)
	cuerpo.rotation.y = atan2(hasta.x - desde.x, hasta.y - desde.y)
	return cuerpo


func _material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TOON
	material.set_shader_parameter(&"color", color)
	return material


func _suelo(sitio: Vector2) -> Vector3:
	return Vector3(sitio.x, _terreno.altura_en(sitio.x, sitio.y) + 0.05, sitio.y)


func _activo(encargo: Encargo) -> bool:
	return Encargos.estado_de(encargo) == Encargos.Estado.ACTIVO


func _contado(encargo: Encargo, clave: StringName) -> bool:
	return Encargos.contado(encargo, clave)


func _clave_habitante(indice: int) -> StringName:
	return StringName("habitante_%d" % indice)
