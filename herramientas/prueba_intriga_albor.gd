extends "res://herramientas/prueba_albor_encargos.gd"
## Recorre los cuatro encargos de investigación mediante interacciones reales.
## Prepara las entregas anteriores y usa un guardado temporal aislado.
## godot --headless --path . -s herramientas/prueba_intriga_albor.gd
## Con ventana: agregar -- <carpeta_de_capturas>.

const CADENA_DUDAS := preload("res://encargos/puerto_albor_dudas_razonables.tres")
const CADENA_TESTIGO := preload("res://encargos/puerto_albor_testigo_silenciado.tres")
const CADENA_LUZ := preload("res://encargos/puerto_albor_echa_luz.tres")
const CADENA_ROSTRO := preload("res://encargos/puerto_albor_rostro_del_engano.tres")
const CADENA_MONTANA := preload("res://encargos/la_voz_misterios_de_la_montana.tres")

var _intriga: Node3D
var _guardado: Node


func _correr() -> void:
	seed(82547)
	if DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().is_empty():
		_salida = OS.get_cmdline_user_args()[0]
		DirAccess.make_dir_recursive_absolute(_salida)
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1440, 900)
		# Si otra ventana la tapa, macOS deja de dibujarla y la captura espera para
		# siempre. Queda arriba, pero sin tomar el foco ni el ratón de quien usa la
		# computadora (las entradas de la prueba son simuladas).
		root.always_on_top = true
		root.unfocusable = true
		root.mouse_passthrough = true
	_interfaz = root.get_node("Interfaz")
	_encargos = root.get_node("Encargos")
	_guardado = root.get_node("Guardado")
	var temporal := "/tmp/emblema_intriga_guardado_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(temporal)
	_guardado.ruta = temporal.path_join("partida.json")

	_preparar_entregas()
	change_scene_to_file(ESCENA)
	await scene_changed
	await _fisica(35)
	_enlazar_intriga()
	if not _verificar(_encargos.estado_de(IMPOSTOR) == 1, "La partida anterior reactiva la misión dorada de investigación"):
		return
	if not _verificar(_intriga.get_node("HabitanteDesconfiado").visible, "El habitante aparece tras entregar la primera tanda"):
		return
	if not _verificar(_intriga.get_node("LiderAlbor").visible and not _intriga.get_node("LiderAlbor/Interactuable").disponible, "El líder está en su patio, pero el acceso comienza bloqueado"):
		return
	if not await _hablar("IntrigaAlbor/HabitanteDesconfiado", CADENA_DUDAS, false):
		return
	for i in 3:
		var nombre: String = ["HabitanteDeAlbor", "Barquero", "Pescadora"][i]
		if not await _charlar(nombre + "/Conversacion"):
			return
		if not _verificar(_encargos.avance_de(CADENA_DUDAS) == i + 1, "Testimonio único · %d/3" % (i + 1)):
			return
		if i == 0:
			if not await _charlar(nombre + "/Conversacion"):
				return
			if not _verificar(_encargos.avance_de(CADENA_DUDAS) == 1, "Repetir un testimonio no duplica el avance"):
				return
	await _vista("albor_dudas_cumplidas", Vector3(98, 7, -166), Vector3(80, 2, -162))
	if not await _hablar("IntrigaAlbor/HabitanteDesconfiado", CADENA_DUDAS, true):
		return
	if not _verificar(not _intriga.get_node("HabitanteDesconfiado").visible, "El habitante deja Albor tras la investigación"):
		return
	if not await _hablar("IntrigaAlbor/TablonAlbor", CADENA_TESTIGO, false):
		return
	if not await _viajar("BoteAlCayo", "LlegadaCayo"):
		return
	if not _verificar(_intriga.get_node("Testigo").visible and not _intriga.get_node("Nota/Interactuable").disponible, "Víctima visible y nota pendiente del enfrentamiento"):
		return
	if not await _charlar("IntrigaAlbor/Testigo/Interactuable"):
		return
	if not _verificar(_encargos.contado(CADENA_TESTIGO, &"cuerpo") and _intriga.has_node("Sicario"), "Investigar el cuerpo revela al sicario"):
		return
	if not await _charlar("IntrigaAlbor/Testigo/Interactuable"):
		return
	if not _verificar(_encargos.avance_de(CADENA_TESTIGO) == 1, "El hallazgo del cuerpo cuenta una vez"):
		return
	if not await _enfrentar_intriga("IntrigaAlbor/Sicario", true):
		return
	if not await _ganar_intriga("Sicario"):
		return
	if not _verificar(_encargos.contado(CADENA_TESTIGO, &"sicario"), "La victoria del sicario queda registrada"):
		return
	if not await _charlar("IntrigaAlbor/Nota/Interactuable"):
		return
	if not _verificar(_encargos.contado(CADENA_TESTIGO, &"nota") and _encargos.avance_de(CADENA_TESTIGO) == 3, "La nota se incorpora a las pruebas"):
		return
	await _foto("albor_seguimiento_nota")
	await _vista("albor_testigo_y_nota", Vector3(124, 7, -180), Vector3(115, 1, -190))
	# Reconstruir la escena debe conservar víctima, prueba y derrota del sicario.
	if not _verificar(_guardado.guardar() and _guardado.cargar(), "Guardar y continuar con la nota"):
		return
	await scene_changed
	await _fisica(35)
	_enlazar_intriga()
	if not _verificar(_intriga.get_node("Testigo").visible and not _intriga.has_node("Sicario"), "Al continuar la víctima permanece y el sicario no reaparece"):
		return
	if not _verificar(not _intriga.get_node("Nota/Interactuable").disponible and _encargos.avance_de(CADENA_TESTIGO) == 3, "La nota recogida no se duplica después de cargar"):
		return
	if not await _viajar("BoteAAlbor", "LlegadaAlbor"):
		return
	_colocar(Vector3(82, 0, -161))
	await _fisica(10)
	if not await _esperar(func() -> bool: return _interfaz.dialogo.abierto, "La acusación se presenta al regresar a Albor"):
		return
	await _cerrar_dialogo()
	if not _verificar(_encargos.contado(CADENA_TESTIGO, &"acusacion"), "La acusación queda registrada"):
		return
	_colocar(Vector3(75, 0, 30))
	await _fisica(15)
	if not _verificar(_encargos.estado_de(CADENA_TESTIGO) == 3, "La huida a Puerto Junco completa El testigo silenciado"):
		return
	var tablon_junco: Node = current_scene.get_node("Tablon")
	var tablon_albor: Node = _intriga.get_node("TablonAlbor")
	if not _verificar(tablon_junco._encargo_actual() == CADENA_LUZ and tablon_albor._encargo_actual() == CADENA_LUZ, "Los dos tablones ofrecen Echa luz sobre tanta oscuridad"):
		return
	if not await _hablar("Tablon", CADENA_LUZ, false):
		return
	if not await _charlar("JefePesquero/NotaDeAlbor"):
		return
	var acompanante: Node3D = _intriga.get_node("JefeAcompanante")
	if not _verificar(_encargos.contado(CADENA_LUZ, &"jefe") and acompanante.visible and not current_scene.get_node("JefePesquero").visible, "El jefe reconoce la nota y se incorpora como acompañante"):
		return
	if not _verificar(acompanante.collision_layer == 0 and not acompanante.get_node("Interactuable").disponible, "El acompañante no frena a la cámara ni roba la conversación"):
		return
	# Camina de a pasos cortos, como al jugar: el jefe sigue el rastro.
	var anterior := acompanante.global_position
	# Sale de Junco por el camino principal, hacia el oeste.
	await _caminar(Vector3(60, 0, 33))
	await _fisica(30)
	var distancia := Vector2(acompanante.global_position.x - _jugador.global_position.x, acompanante.global_position.z - _jugador.global_position.z).length()
	if not _verificar(acompanante.global_position.distance_to(anterior) > 3.0 and distancia < 4.0, "El jefe acompaña al protagonista (a %.1f m)" % distancia):
		return
	await _vista("albor_jefe_acompana", _jugador.global_position + Vector3(3, 2.6, 5), _jugador.global_position + Vector3(-1, 0.9, 0))
	_colocar(Vector3(70, 0, -161))
	await _fisica(14)
	await _vista("albor_patio_cerrado", Vector3(74, 9, -155), Vector3(57, 3, -164))
	for i in 3:
		if not await _charlar("IntrigaAlbor/Entrada%d/Interactuable" % i):
			return
		if not _verificar(_encargos.contado(CADENA_LUZ, StringName("habitante_%d" % i)), "Habitante convencido · %d/3" % (i + 1)):
			return
	await _fisica(4)
	if not _verificar(_encargos.estado_de(CADENA_LUZ) == 3 and _intriga.get_node("PasoAlLider/Colision").disabled and _intriga.get_node("LiderAlbor/Interactuable").disponible, "Tres testimonios abren el sector del líder y completan el encargo"):
		return
	if not _verificar(not _intriga.get_node("Entrada0").visible and not _intriga.get_node("Entrada2").visible, "Los habitantes de la entrada dejan libre el portón"):
		return
	await _vista("albor_patio_abierto", Vector3(74, 9, -155), Vector3(57, 3, -164))
	await _foto("albor_acceso_al_lider")
	if not await _hablar("IntrigaAlbor/LiderAlbor", CADENA_ROSTRO, false):
		return
	if not await _enfrentar_intriga("IntrigaAlbor/Profeta", true):
		return
	var panel: Control = _interfaz.combate
	if not _verificar(panel._limite_de_turnos == 15, "El enfrentamiento con el profeta tiene límite de 15 turnos"):
		return
	# Se abandona el primer encuentro para comprobar un reintento legítimo.
	if not await _esperar(func() -> bool: return not panel._en_animacion, "Acciones disponibles para huir"):
		return
	await _pulsar("combate_huir")
	await _pulsar("ui_accept")
	await _reposo()
	if not _verificar(_intriga.has_node("Profeta") and _encargos.avance_de(CADENA_ROSTRO) == 0, "Huir conserva al profeta y permite volver a confrontarlo"):
		return
	if not await _enfrentar_intriga("IntrigaAlbor/Profeta", true):
		return
	if not await _ganar_intriga("Profeta"):
		return
	if not await _esperar(func() -> bool: return _interfaz.dialogo.abierto, "Cierre de la investigación"):
		return
	# Primero la narración del cierre; después habla La Voz.
	var dialogo: Node = _interfaz.dialogo
	for i in 6:
		if dialogo.get("_nombre").text == "La Voz":
			break
		await _pulsar("interactuar")
		await _reposo()
	if not _verificar(dialogo.abierto and dialogo.get("_nombre").text == "La Voz", "La Voz anuncia la siguiente misión"):
		return
	await _esperar(func() -> bool: return not dialogo.get("_escribiendo"), "Frase de La Voz completa")
	await _foto("albor_vision_montana")
	await _cerrar_dialogo()
	await _fisica(5)
	if not _verificar(not _intriga.has_node("Profeta") and not _intriga.get_node("JefeAcompanante").visible, "El profeta se esfuma y termina el acompañamiento"):
		return
	if not _verificar(_encargos.estado_de(CADENA_ROSTRO) == 3 and _encargos.estado_de(IMPOSTOR) == 3 and _encargos.estado_de(CADENA_MONTANA) == 1, "El desenlace cierra la investigación y activa Desentraña los misterios de la montaña"):
		return
	var cuenta_final: int = _encargos.avance_de(CADENA_ROSTRO)
	await _fisica(10)
	if not _verificar(cuenta_final == 1 and _encargos.avance_de(CADENA_ROSTRO) == cuenta_final, "La victoria y el cierre se registran una sola vez"):
		return
	print("ALBOR INVESTIGACIÓN · OK")
	current_scene.queue_free()
	await process_frame
	await process_frame
	quit()


func _preparar_entregas() -> void:
	var registros: Array[Dictionary] = []
	for archivo in DirAccess.get_files_at("res://encargos"):
		if archivo.begins_with("puerto_junco_") and archivo.ends_with(".tres"):
			var encargo: Resource = load("res://encargos/" + archivo)
			registros.append({"id": String(encargo.id), "estado": 3, "avance": encargo.cantidad, "elementos": []})
	for encargo in [GRUTA, ARENA, CAPARAZONES, IMPOSTOR]:
		registros.append({"id": String(encargo.id), "estado": 3, "avance": encargo.cantidad, "elementos": []})
	_encargos.desde_diccionario({"encargos": registros})


# Lleva al protagonista hasta "hasta" en pasos de 30 cm, uno cada dos cuadros de física.
func _caminar(hasta: Vector3) -> void:
	var desde := _jugador.global_position
	var pasos := maxi(1, ceili(Vector2(hasta.x - desde.x, hasta.z - desde.z).length() / 0.3))
	for i in range(1, pasos + 1):
		_colocar(desde.lerp(hasta, float(i) / pasos))
		await _fisica(2)


func _enlazar_intriga() -> void:
	_enlazar()
	_intriga = current_scene.get_node("IntrigaAlbor")


func _charlar(ruta: String) -> bool:
	if not await _usar_zona(ruta):
		return false
	if not await _esperar(func() -> bool: return _interfaz.dialogo.abierto, "Conversación · " + ruta):
		return false
	await _cerrar_dialogo()
	return true


func _usar_zona(ruta: String) -> bool:
	var zona: Node3D = current_scene.get_node(ruta)
	if not _verificar(zona.disponible, "Interacción disponible · " + ruta):
		return false
	for margen: Vector3 in [Vector3(0.7, 0, 0), Vector3(-0.7, 0, 0), Vector3(0, 0, 0.9), Vector3(0, 0, -0.9)]:
		_colocar(zona.global_position + margen)
		await _fisica(10)
		if _jugador.get_node("Alcance").get("_a_mano") == zona:
			await _pulsar("interactuar")
			return true
	return _verificar(false, "Alcance físico de " + ruta)


func _enfrentar_intriga(ruta: String, confrontar: bool) -> bool:
	if not await _usar_zona(ruta + "/Interactuable"):
		return false
	if confrontar:
		if not await _esperar(func() -> bool: return _interfaz.dialogo.abierto, "Diálogo previo al combate · " + ruta):
			return false
		await _cerrar_dialogo()
	return await _esperar(func() -> bool: return _interfaz.combate.visible, "Inicio del combate · " + ruta)


func _ganar_intriga(nombre: String) -> bool:
	var panel: Control = _interfaz.combate
	var continuar: Button = panel.get_node("Columna/Continuar")
	var atacar: Button = panel.get_node("Columna/Acciones/Atacar")
	var estado: Label = panel.get_node("Columna/Cabecera/Estado")
	for turno in 24:
		if not await _esperar(func() -> bool: return continuar.visible or not atacar.disabled, "Turno de " + nombre):
			return false
		if continuar.visible:
			break
		var pronostico: Label = panel.get_node("Columna/Senal/Fila/Pronostico")
		var preparar: Button = panel.get_node("Columna/Acciones/Preparar")
		if "Embestida" in pronostico.text:
			await _pulsar("combate_defender")
		elif not preparar.disabled and ("Coraza" in pronostico.text or "Guardia" in pronostico.text):
			await _pulsar("combate_preparar")
		else:
			await _pulsar("combate_atacar")
	if not _verificar(estado.text == "Victoria", "Victoria contra " + nombre):
		return false
	await _pulsar("ui_accept")
	await _reposo()
	return true
