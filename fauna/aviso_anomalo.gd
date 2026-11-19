class_name AvisoAnomalo
extends CanvasLayer
## Aviso breve en pantalla al obtener una Ficha Anómala.
##
## No depende de la interfaz principal: se crea solo la primera vez que hace
## falta, para que la Fauna Anómala no toque los archivos de interfaz/.

const DURACION := 3.5
const TEMA := preload("res://interfaz/tema.tres")

var _panel: PanelContainer
var _titulo: Label
var _detalle: Label
var _tiempo := 0.0


## Muestra el aviso de la ficha recién obtenida.
static func mostrar(arbol: SceneTree, especie: String) -> void:
	var aviso := arbol.root.get_node_or_null("AvisoAnomalo") as AvisoAnomalo
	if aviso == null:
		aviso = AvisoAnomalo.new()
		aviso.name = "AvisoAnomalo"
		arbol.root.add_child(aviso)
	aviso._anunciar(especie)


func _init() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.theme = TEMA
	_panel.theme_type_variation = &"PanelHUD"
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -190.0
	_panel.offset_right = 190.0
	_panel.offset_top = 90.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var columna := VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_titulo = Label.new()
	_titulo.theme_type_variation = &"Enfasis"
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detalle = Label.new()
	_detalle.theme_type_variation = &"Secundario"
	_detalle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_titulo)
	columna.add_child(_detalle)
	_panel.add_child(columna)
	add_child(_panel)
	_panel.visible = false


func _anunciar(especie: String) -> void:
	_titulo.text = "Ficha Anómala obtenida"
	var faltan := FaunaAnomala.FICHAS_POR_CANJE - FaunaAnomala.fichas % FaunaAnomala.FICHAS_POR_CANJE
	_detalle.text = "%s Anómalo · Fichas: %d (faltan %d para un canje)" % [especie, FaunaAnomala.fichas, faltan]
	_tiempo = DURACION
	_panel.visible = true


func _process(delta: float) -> void:
	if _tiempo <= 0.0:
		return
	_tiempo -= delta
	_panel.modulate.a = clampf(_tiempo * 3.0, 0.0, 1.0)
	_panel.visible = _tiempo > 0.0
