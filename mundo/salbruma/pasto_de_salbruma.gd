@tool
extends Node3D
## Reparte matas cortas y altas en grupos para dibujarlas por lotes.

const TRAZADO := preload("res://mundo/salbruma/trazado_salbruma.gd")
const SHADER := preload("res://shaders/pasto.gdshader")

const LADO_DEL_LOTE := 18.0
const ALCANCE_DEL_RELLENO := 43.0
const ALCANCE_DE_LAS_MATAS := 91.0

@export var terreno: TerrenoSalbruma
@export var region := Rect2(-155, -130, 278, 203)
@export var semilla := 48
## Un paso menor rellena más las praderas. Se planta una mata por celda.
@export_range(0.30, 1.5, 0.01) var paso_de_siembra := 0.44

var _malla_baja: ArrayMesh
var _malla_alta: ArrayMesh


func _ready() -> void:
	if terreno:
		terreno.generado.connect(_repartir)
		_repartir()


func _repartir() -> void:
	for hijo in get_children():
		remove_child(hijo)
		hijo.queue_free()
	_malla_baja = _malla_de_mata(0.36, 6, 17, Color("85964e"))
	_malla_alta = _malla_de_mata(0.82, 6, 31, Color("768b47"))

	var azar := RandomNumberGenerator.new()
	azar.seed = semilla
	var manchones := FastNoiseLite.new()
	manchones.seed = semilla
	manchones.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	manchones.frequency = 0.088
	for j in ceili(region.size.y / LADO_DEL_LOTE):
		for i in ceili(region.size.x / LADO_DEL_LOTE):
			var inicio := region.position + Vector2(i, j) * LADO_DEL_LOTE
			var extension := (region.end - inicio).min(Vector2.ONE * LADO_DEL_LOTE)
			_plantar_lote(Rect2(inicio, extension), azar, manchones)


func _plantar_lote(lote: Rect2, azar: RandomNumberGenerator, manchones: FastNoiseLite) -> void:
	var centro := lote.get_center()
	var bajas: Array[Transform3D] = []
	var altas: Array[Transform3D] = []
	var relleno_bajo: Array[Transform3D] = []
	var relleno_alto: Array[Transform3D] = []
	var celdas := Vector2i(ceili(lote.size.x / paso_de_siembra), ceili(lote.size.y / paso_de_siembra))
	var paso := lote.size / Vector2(celdas)
	for j in celdas.y:
		for i in celdas.x:
			var offset := Vector2(azar.randf_range(0.10, 0.90), azar.randf_range(0.10, 0.90))
			var punto := lote.position + (Vector2(i, j) + offset) * paso
			var h := terreno.altura_en(punto.x, punto.y)
			if h < 0.16 or h > 17.0 or terreno.cobertura_de_camino(punto) > 0.16:
				continue
			var pendiente := absf(terreno.altura_en(punto.x + 0.8, punto.y) - h) + absf(terreno.altura_en(punto.x, punto.y + 0.8) - h)
			if pendiente > 0.72:
				continue

			var dentro_de_junco := ((punto - TRAZADO.PUERTO) / Vector2(28, 16)).length() < 1.0
			var mancha := 0.5 + 0.5 * manchones.get_noise_2dv(punto)
			if dentro_de_junco and azar.randf() > 0.14:
				continue
			var alto_en_la_orilla := h < 1.58
			var probabilidad_alta := lerpf(0.48, 0.89, mancha) if alto_en_la_orilla else smoothstep(0.40, 0.66, mancha) * 0.76
			# Mantenemos la cobertura del suelo y dejamos ver a los lagartos bajos.
			probabilidad_alta *= lerpf(1.0, 0.43, TRAZADO.peso_de_marisma(punto))
			var es_alta := not dentro_de_junco and azar.randf() < probabilidad_alta
			var base := i % 2 == 0 and j % 2 == 0
			var grupo := altas if es_alta else bajas
			if not base:
				grupo = relleno_alto if es_alta else relleno_bajo
			var giro := Basis.from_euler(Vector3(0, azar.randf_range(0, TAU), 0))
			var escala := azar.randf_range(0.70, 1.21)
			var posicion := Vector3(punto.x - centro.x, h - 0.034, punto.y - centro.y)
			grupo.append(Transform3D(giro.scaled(Vector3.ONE * escala), posicion))
	_dibujar_lote(centro, bajas, _malla_baja, azar, ALCANCE_DE_LAS_MATAS)
	_dibujar_lote(centro, altas, _malla_alta, azar, ALCANCE_DE_LAS_MATAS)
	_dibujar_lote(centro, relleno_bajo, _malla_baja, azar, ALCANCE_DEL_RELLENO)
	_dibujar_lote(centro, relleno_alto, _malla_alta, azar, ALCANCE_DEL_RELLENO)


func _dibujar_lote(centro: Vector2, matas: Array[Transform3D], malla: ArrayMesh, azar: RandomNumberGenerator, alcance: float) -> void:
	if matas.is_empty():
		return
	var grupo := MultiMesh.new()
	grupo.transform_format = MultiMesh.TRANSFORM_3D
	grupo.use_custom_data = true
	grupo.mesh = malla
	grupo.instance_count = matas.size()
	for i in matas.size():
		grupo.set_instance_transform(i, matas[i])
		grupo.set_instance_custom_data(i, Color(azar.randf(), 0, 0, 1))
	var lote := MultiMeshInstance3D.new()
	lote.multimesh = grupo
	lote.position = Vector3(centro.x, 0, centro.y)
	lote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lote.extra_cull_margin = 1.0
	lote.visibility_range_end = alcance + LADO_DEL_LOTE
	add_child(lote)
	lote.set_instance_shader_parameter(&"alcance", alcance)


func _malla_de_mata(altura: float, hojas: int, semilla_de_malla: int, tono: Color) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normales := PackedVector3Array()
	var uv := PackedVector2Array()
	var azar := RandomNumberGenerator.new()
	azar.seed = semilla_de_malla
	for hoja in hojas:
		var direccion := Vector3.FORWARD.rotated(Vector3.UP, TAU * float(hoja) / float(hojas))
		var lado := Vector3.UP.cross(direccion)
		var alto := altura * azar.randf_range(0.58, 1.10)
		var ancho := azar.randf_range(0.041, 0.073) * sqrt(altura / 0.36)
		var raiz := direccion * azar.randf_range(0.045, 0.17)
		var medio := raiz + Vector3.UP * alto * 0.52 + direccion * alto * 0.28
		var punta := raiz + Vector3.UP * alto + direccion * alto * 0.59
		var base_a := raiz - lado * ancho
		var base_b := raiz + lado * ancho
		var medio_a := medio - lado * ancho * 0.72
		var medio_b := medio + lado * ancho * 0.72
		vertices.append_array(PackedVector3Array([
			base_a, medio_a, base_b, medio_a, medio_b, base_b, medio_a, punta, medio_b,
		]))
		for y in [0.0, 0.52, 0.0, 0.52, 0.52, 0.0, 0.52, 1.0, 0.52]:
			uv.append(Vector2(0, y))
			normales.append(Vector3.UP)

	var datos := []
	datos.resize(Mesh.ARRAY_MAX)
	datos[Mesh.ARRAY_VERTEX] = vertices
	datos[Mesh.ARRAY_NORMAL] = normales
	datos[Mesh.ARRAY_TEX_UV] = uv
	var malla := ArrayMesh.new()
	malla.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, datos)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"color_hoja", tono)
	malla.surface_set_material(0, material)
	return malla
