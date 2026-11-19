extends Control

const SALBRUMA := "res://mundo/salbruma/salbruma.tscn"

@onready var _inicio: PanelContainer = $Inicio
@onready var _acciones: VBoxContainer = $Inicio/Columna/Acciones
@onready var _continuar: Button = $Inicio/Columna/Acciones/Continuar
@onready var _nueva: Button = $Inicio/Columna/Acciones/Nueva
@onready var _ver_controles: Button = $Inicio/Columna/Acciones/Controles
@onready var _confirmacion: VBoxContainer = $Inicio/Columna/Confirmacion
@onready var _cancelar: Button = $Inicio/Columna/Confirmacion/Cancelar
@onready var _controles: PanelContainer = $Controles
@onready var _volver: Button = $Controles/Columna/Cabecera/Volver
@onready var _estado: Label = $Inicio/Columna/Estado


func _ready() -> void:
	Interfaz.establecer_en_menu_principal(true)
	tree_exiting.connect(Interfaz.establecer_en_menu_principal.bind(false))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_continuar.pressed.connect(_cargar_partida)
	_nueva.pressed.connect(_pedir_partida_nueva)
	_ver_controles.pressed.connect(_mostrar_controles.bind(true))
	$Inicio/Columna/Acciones/Salir.pressed.connect(get_tree().quit)
	_cancelar.pressed.connect(_cancelar_borrado)
	$Inicio/Columna/Confirmacion/Confirmar.pressed.connect(_empezar_de_nuevo)
	_volver.pressed.connect(_mostrar_controles.bind(false))
	_continuar.disabled = not _hay_partida()
	if _continuar.disabled:
		_nueva.grab_focus()
	else:
		_continuar.grab_focus()
	Interfaz.animar_entrada(_inicio)


func _unhandled_input(evento: InputEvent) -> void:
	if not (evento.is_action_pressed(&"ui_cancel") or evento.is_action_pressed(&"pausar")):
		return
	if _controles.visible:
		_mostrar_controles(false)
	elif _confirmacion.visible:
		_cancelar_borrado()
	else:
		return
	get_viewport().set_input_as_handled()


func _hay_partida() -> bool:
	return Guardado.automatico and Guardado.hay_partida()


func _cargar_partida() -> void:
	if not _hay_partida():
		_continuar.disabled = true
		_nueva.grab_focus()
		_mostrar_error("Ya no hay una partida guardada.")
		return
	if not Guardado.cargar():
		_mostrar_error(Guardado.ultimo_mensaje)
		return
	_abrir_salbruma()


func _pedir_partida_nueva() -> void:
	if _hay_partida():
		_estado.hide()
		_acciones.hide()
		_confirmacion.show()
		_cancelar.grab_focus()
	else:
		_abrir_salbruma()


func _cancelar_borrado() -> void:
	_confirmacion.hide()
	_acciones.show()
	_continuar.disabled = not _hay_partida()
	_nueva.grab_focus()


func _empezar_de_nuevo() -> void:
	if not Guardado.borrar():
		_cancelar_borrado()
		_mostrar_error(Guardado.ultimo_mensaje)
		return
	_abrir_salbruma()


func _abrir_salbruma() -> void:
	if get_tree().change_scene_to_file(SALBRUMA) != OK:
		_cancelar_borrado()
		_mostrar_error("No se pudo abrir Salbruma.")


func _mostrar_controles(activos: bool) -> void:
	_controles.visible = activos
	_inicio.visible = not activos
	if activos:
		_volver.grab_focus()
		Interfaz.animar_entrada(_controles)
	else:
		_ver_controles.grab_focus()


func _mostrar_error(mensaje: String) -> void:
	_estado.text = mensaje
	_estado.show()
