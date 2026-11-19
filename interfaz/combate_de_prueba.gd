class_name CombateDePrueba
extends PanelContainer
## Alterna la decisión del jugador con una respuesta anunciada del rival.

signal terminado(victoria: bool)

const REGLAS := preload("res://nucleo/maniobras_de_combate.gd")
const INTENCION := REGLAS.Intencion
const ATAJOS := [&"combate_atacar", &"combate_defender", &"combate_preparar", &"combate_huir"]
const NOMBRES := ["Atacar", "Defender", "Preparar", "Huir"]
const GUIAS := [
	"Tirá para golpear al rival.",
	"Reducí el daño y dejá listo un golpe certero si el rival embiste.",
	"Dedicá el turno a asegurar el próximo golpe.",
	"Terminá el encuentro y volvé a explorar.",
]

var cerrado_en := -100000
var _vida_protagonista := 0
var _vida_rival_actual := 0
var _vida_rival_maxima := 0
var _dano_rival := 0
var _estilo: ManiobrasDeCombate.Estilo
var _intencion: ManiobrasDeCombate.Intencion
var _limite_de_turnos := 0
var _turno := 0
var _certero_listo := false
var _en_animacion := false
var _resuelto := false
var _victoria := false
var _modelo_protagonista: Node3D
var _modelo_rival: Node3D
var _modelo_caido: Node3D
var _reposo_del_caido: Transform3D
var _raton_anterior := Input.MOUSE_MODE_VISIBLE
var _estilo_de_senal: StyleBoxFlat
var _animacion_de_vida: Tween

@onready var _estado: Label = $Columna/Cabecera/Estado
@onready var _relato: Label = $Columna/Relato
@onready var _nombre: Label = $Columna/Vidas/Rival/Nombre
@onready var _vida_propia: ProgressBar = $Columna/Vidas/Protagonista/Barra
@onready var _vida_rival: ProgressBar = $Columna/Vidas/Rival/Barra
@onready var _cantidad_propia: Label = $Columna/Vidas/Protagonista/Barra/Cantidad
@onready var _cantidad_rival: Label = $Columna/Vidas/Rival/Barra/Cantidad
@onready var _senal: PanelContainer = $Columna/Senal
@onready var _pronostico: Label = $Columna/Senal/Fila/Pronostico
@onready var _ventaja: Label = $Columna/Senal/Fila/Ventaja
@onready var _acciones: HBoxContainer = $Columna/Acciones
@onready var _atacar: Button = $Columna/Acciones/Atacar
@onready var _defender: Button = $Columna/Acciones/Defender
@onready var _preparar: Button = $Columna/Acciones/Preparar
@onready var _huir: Button = $Columna/Acciones/Huir
@onready var _continuar: Button = $Columna/Continuar
@onready var _detalle: Label = $Columna/Detalle
@onready var _gestos: GestosDeCombate = $Gestos
@onready var _botones: Array[Button] = [_atacar, _defender, _preparar, _huir]


func _ready() -> void:
	_vida_propia.max_value = REGLAS.VIDA_PROTAGONISTA
	_estilo_de_senal = _senal.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	_senal.add_theme_stylebox_override(&"panel", _estilo_de_senal)
	_atacar.pressed.connect(_al_atacar)
	_defender.pressed.connect(_al_defender)
	_preparar.pressed.connect(_al_preparar)
	_huir.pressed.connect(_al_huir)
	_continuar.pressed.connect(_cerrar)
	for boton in _botones:
		boton.focus_entered.connect(_mostrar_detalle.bind(boton))
		boton.mouse_entered.connect(_mostrar_detalle.bind(boton))
		boton.mouse_exited.connect(_restaurar_detalle)
	Interfaz.dispositivo_cambiado.connect(_actualizar_atajos)


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or _en_animacion or _resuelto or evento.is_echo():
		return
	for i in ATAJOS.size():
		if evento.is_action_pressed(ATAJOS[i]):
			get_viewport().set_input_as_handled()
			if not _botones[i].disabled:
				_botones[i].pressed.emit()
			return


func iniciar(
	protagonista: Node3D, rival: Node3D, nombre: String, vida: int, dano: int,
	estilo: ManiobrasDeCombate.Estilo, limite := 0
) -> void:
	_modelo_protagonista = protagonista
	_modelo_rival = rival
	_estilo = estilo
	_dano_rival = dano
	_limite_de_turnos = limite
	_vida_protagonista = REGLAS.VIDA_PROTAGONISTA
	_vida_rival_actual = vida
	_vida_rival_maxima = vida
	_turno = 0
	_certero_listo = false
	_resuelto = false
	_estado.remove_theme_color_override(&"font_color")

	_nombre.text = nombre
	_vida_rival.max_value = vida
	_acciones.show()
	_senal.show()
	_detalle.show()
	_continuar.hide()
	_bloquear_acciones(true)
	_actualizar_vida(true)
	_actualizar_certero()
	_mostrar_senal("Tirada de iniciativa", Color("b9c3d9"))
	_raton_anterior = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()

	var iniciativa_propia := randi_range(1, 20)
	var iniciativa_rival := randi_range(1, 20)
	var actuas_primero := iniciativa_propia >= iniciativa_rival
	var primero := "Vos primero." if actuas_primero else "%s se adelanta." % nombre
	var relato := "Tiradas de iniciativa · Vos %d / Rival %d. %s" % [iniciativa_propia, iniciativa_rival, primero]
	_estado.text = "Iniciativa"
	_relato.text = relato
	await get_tree().create_timer(0.38).timeout
	if not actuas_primero:
		relato += "\n" + await _ataque_rival(false, INTENCION.GOLPE)
	_mostrar_turno(relato, _atacar)


func _al_atacar() -> void:
	if _resuelto or _en_animacion:
		return
	_bloquear_acciones(true)
	var certero := _certero_listo
	_certero_listo = false
	_actualizar_certero()
	_estado.text = "Golpe certero" if certero else "Tu ataque"
	_relato.text = ""
	var tirada := randi_range(1, 20)
	var dano := REGLAS.ataque_propio(tirada, certero, _intencion)
	var protegido := not certero and _intencion == INTENCION.CORAZA
	var fuerza := 1.33 if certero else 1.0
	await _gestos.golpear(_modelo_protagonista, _modelo_rival, dano, protegido, _danar_rival.bind(dano), fuerza)
	var relato := "Tu ataque · %d → falla." % tirada
	if certero:
		relato = "Golpe certero · %d de daño." % dano
	elif dano > 0:
		relato = "Tu ataque · %d → %d de daño." % [tirada, dano]
		if protegido:
			relato += " La coraza lo reduce." if _estilo == REGLAS.Estilo.ACORAZADO else " La guardia lo reduce."
	if _vida_rival_actual == 0:
		await _resolver("Victoria", relato, true, _modelo_rival)
	else:
		await _turno_de_rival(relato, false, _atacar)


func _al_defender() -> void:
	if _resuelto or _en_animacion:
		return
	_bloquear_acciones(true)
	_estado.text = "En guardia"
	_relato.text = "Te preparás para recibir el golpe."
	await _gestos.defender(_modelo_protagonista)
	await _turno_de_rival(_relato.text, true, _defender)


func _al_preparar() -> void:
	if _resuelto or _en_animacion or _certero_listo:
		return
	_certero_listo = true
	_bloquear_acciones(true)
	_actualizar_certero()
	_estado.text = "Preparás el ataque"
	_relato.text = "Tu próximo golpe es certero."
	await _gestos.alistar(_modelo_protagonista, -0.16, "Listo", Color("96e3d3"))
	await _turno_de_rival(_relato.text, false, _atacar)


func _al_huir() -> void:
	if not _resuelto and not _en_animacion:
		await _resolver("Huida", "Terminaste el encuentro.", false)


func _turno_de_rival(relato: String, defendido: bool, foco: Button) -> void:
	_estado.text = "Turno rival"
	_relato.text = relato
	var respuesta := await _respuesta_rival(defendido)
	relato += "\n" + respuesta
	_gestos.bajar_guardia(_modelo_protagonista)
	if _vida_protagonista == 0:
		await _resolver("Derrota", relato, false, _modelo_protagonista)
	elif _limite_de_turnos > 0 and _turno >= _limite_de_turnos:
		await _resolver("Se acabaron los turnos", relato, false)
	else:
		_mostrar_turno(relato, foco)


func _respuesta_rival(defendido: bool) -> String:
	match _intencion:
		INTENCION.CARGA:
			await _gestos.alistar(_modelo_rival, 0.30, "Carga", Color("f5b36d"))
			return "El rival carga la embestida."
		INTENCION.CORAZA:
			await _gestos.alistar(_modelo_rival, -0.25, "Cubierto", Color("b9c3d9"))
			return "El rival se cubre y cambia de postura."
		_:
			return await _ataque_rival(defendido, _intencion)


func _ataque_rival(defendido: bool, maniobra: ManiobrasDeCombate.Intencion) -> String:
	var fuerte := maniobra == INTENCION.EMBESTIDA
	var tirada := randi_range(1, 20)
	var dano := REGLAS.ataque_rival(tirada, _dano_rival, defendido, maniobra)
	var fuerza := 1.64 if fuerte else 1.0
	await _gestos.golpear(_modelo_rival, _modelo_protagonista, dano, defendido, _danar_protagonista.bind(dano), fuerza)
	var tipo := "Embestida" if fuerte else "Ataque rival"
	if fuerte and defendido:
		_certero_listo = true
		return "%s · %d de daño. Golpe certero listo." % [tipo, dano] if dano > 0 else "%s esquivada. Golpe certero listo." % tipo
	if dano == 0:
		return "%s · %d → falla." % [tipo, tirada]
	var detalle := " (bloqueado en parte)" if defendido else ""
	return "%s · %d → %d de daño%s." % [tipo, tirada, dano, detalle]


func _mostrar_turno(relato: String, foco: Button) -> void:
	_turno += 1
	_intencion = REGLAS.intencion_de(_estilo, _turno)
	var numero := "%d / %d" % [_turno, _limite_de_turnos] if _limite_de_turnos > 0 else str(_turno)
	_estado.text = "Turno %s · Elegí una acción" % numero
	_relato.text = relato
	_actualizar_certero()
	_anunciar_rival()
	_bloquear_acciones(false)
	var elegido := _atacar if foco.disabled else foco
	elegido.grab_focus()
	_mostrar_detalle(elegido)


func _anunciar_rival() -> void:
	match _intencion:
		INTENCION.CARGA:
			_mostrar_senal("Rival · Carga para el próximo turno", Color("eac891"))
			_modelo_rival.rotation.x = 0.14
		INTENCION.EMBESTIDA:
			_mostrar_senal("Rival · Embestida. Defendé para contraatacar", Color("ffb28b"))
			_modelo_rival.rotation.x = 0.30
		INTENCION.CORAZA:
			var postura := "Coraza" if _estilo == REGLAS.Estilo.ACORAZADO else "Guardia"
			_mostrar_senal("Rival · %s. Reduce los golpes normales" % postura, Color("b9c3d9"))
			_modelo_rival.rotation.x = -0.23
		_:
			_mostrar_senal("Rival · Ataque rápido", Color("ebd9b0"))
			_modelo_rival.rotation.x = 0.0


func _mostrar_senal(texto: String, color: Color) -> void:
	_pronostico.text = texto
	_pronostico.add_theme_color_override(&"font_color", color)
	_estilo_de_senal.border_color = color.darkened(0.30)
	_estilo_de_senal.bg_color = Color("1b252d").lerp(color, 0.10)


func _actualizar_certero() -> void:
	_actualizar_atajos()
	_atacar.theme_type_variation = &"BotonPrincipal" if _certero_listo else &"Button"
	_ventaja.visible = _certero_listo


func _actualizar_atajos() -> void:
	for i in _botones.size():
		var etiqueta: String = "Golpe certero" if i == 0 and _certero_listo else NOMBRES[i]
		var tecla: String = Interfaz.tecla(ATAJOS[i], false)
		_botones[i].text = etiqueta if Interfaz.con_mando else "%s · %s" % [tecla, etiqueta]
	var confirmar: String = Interfaz.tecla(&"ui_accept", Interfaz.con_mando)
	_continuar.text = "%s   Volver a explorar" % confirmar


func _mostrar_detalle(boton: Button) -> void:
	if _en_animacion or _resuelto or boton.disabled:
		return
	_detalle.text = "Acierta y atraviesa la protección del rival." if boton == _atacar and _certero_listo else GUIAS[_botones.find(boton)]


func _restaurar_detalle() -> void:
	var foco := get_viewport().gui_get_focus_owner() as Button
	if foco in _botones:
		_mostrar_detalle(foco)


func _resolver(resultado: String, relato: String, victoria: bool, caido: Node3D = null) -> void:
	_resuelto = true
	_victoria = victoria
	_estado.text = resultado
	_estado.add_theme_color_override(&"font_color", Color("9cceac") if victoria else Color("f0c69a"))
	_relato.text = relato
	_gestos.bajar_guardia(_modelo_protagonista)
	_modelo_rival.rotation.x = 0.0
	if caido:
		_modelo_caido = caido
		_reposo_del_caido = caido.transform
		await _gestos.caer(caido)
	_senal.hide()
	_acciones.hide()
	_detalle.hide()
	_continuar.show()
	_continuar.grab_focus()


func _bloquear_acciones(bloqueadas: bool) -> void:
	_en_animacion = bloqueadas
	for boton in _botones:
		boton.disabled = bloqueadas
	_preparar.disabled = bloqueadas or _certero_listo
	if bloqueadas:
		_detalle.text = ""


func _actualizar_vida(inmediata := false) -> void:
	if _animacion_de_vida and _animacion_de_vida.is_valid():
		_animacion_de_vida.kill()
	if inmediata:
		_vida_propia.value = _vida_protagonista
		_vida_rival.value = _vida_rival_actual
	else:
		_animacion_de_vida = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD)
		_animacion_de_vida.tween_property(_vida_propia, "value", float(_vida_protagonista), 0.22)
		_animacion_de_vida.tween_property(_vida_rival, "value", float(_vida_rival_actual), 0.22)
	_cantidad_propia.text = "%d/%d" % [_vida_protagonista, REGLAS.VIDA_PROTAGONISTA]
	_cantidad_rival.text = "%d/%d" % [_vida_rival_actual, _vida_rival_maxima]


func _danar_protagonista(dano: int) -> void:
	_vida_protagonista = maxi(_vida_protagonista - dano, 0)
	_actualizar_vida()


func _danar_rival(dano: int) -> void:
	_vida_rival_actual = maxi(_vida_rival_actual - dano, 0)
	_actualizar_vida()


func _cerrar() -> void:
	cerrado_en = Time.get_ticks_msec()
	if is_instance_valid(_modelo_caido):
		_modelo_caido.transform = _reposo_del_caido
	_modelo_caido = null
	_modelo_protagonista = null
	_modelo_rival = null
	Input.mouse_mode = _raton_anterior
	hide()
	terminado.emit(_victoria)
