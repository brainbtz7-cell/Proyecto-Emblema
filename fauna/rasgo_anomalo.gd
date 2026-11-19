class_name RasgoAnomalo
extends Node3D
## Aspecto de un animal Anómalo: le cambia la coloración y le agrega un rasgo
## físico visible.
##
## PROVISIONAL: el Documento Maestro dice que la paleta y el rasgo se definen
## para cada especie, y todavía no están definidos. Hasta entonces se usa
## una paleta general (giro de tono y brillo) y, como rasgo, una hilera de
## cristales sobre el lomo. Cada especie puede cambiarlos desde su escena con
## "tono_anomalo" y "rasgo_anomalo" (en CriaturaDePrueba).

const MATERIAL_DE_CRISTAL_COLOR := Color(0.62, 0.95, 1.0)


## Aplica el aspecto Anómalo al modelo de un animal.
## "giro_de_tono": cuánto se desplaza el tono de sus colores (0 a 1).
static func aplicar(modelo: Node3D, giro_de_tono: float, rasgo: PackedScene) -> void:
	_recolorear(modelo, giro_de_tono)
	var adorno: Node3D = rasgo.instantiate() if rasgo else _cristales(modelo)
	adorno.name = "RasgoAnomalo"
	modelo.add_child(adorno)
	_agregar_destellos(modelo)


static func _recolorear(modelo: Node3D, giro_de_tono: float) -> void:
	var ya_cambiados := {}
	for nodo in modelo.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		var original := _material_de(malla)
		var shader := original as ShaderMaterial
		if shader == null or shader.get_shader_parameter("color") == null:
			continue
		# Varias partes comparten material: se cambia una sola vez cada uno.
		var nuevo: ShaderMaterial = ya_cambiados.get(original)
		if nuevo == null:
			nuevo = shader.duplicate()
			var color: Color = shader.get_shader_parameter("color")
			var tono := fposmod(color.h + giro_de_tono, 1.0)
			color = Color.from_hsv(tono, clampf(color.s * 1.35 + 0.12, 0.0, 1.0), clampf(color.v * 1.05, 0.0, 1.0))
			nuevo.set_shader_parameter("color", color)
			nuevo.set_shader_parameter("luz_propia", 0.25)
			ya_cambiados[original] = nuevo
		malla.material_override = nuevo


static func _material_de(malla: MeshInstance3D) -> Material:
	if malla.material_override:
		return malla.material_override
	if malla.get_surface_override_material(0):
		return malla.get_surface_override_material(0)
	if malla.mesh and malla.mesh.get_surface_count() > 0:
		return malla.mesh.surface_get_material(0)
	return null


# Rasgo provisional: cristales que salen del lomo, a lo largo del cuerpo.
static func _cristales(modelo: Node3D) -> Node3D:
	var caja := _caja_del_modelo(modelo)
	var raiz := Node3D.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = MATERIAL_DE_CRISTAL_COLOR
	var prisma := PrismMesh.new()
	prisma.size = Vector3(0.12, 0.34, 0.12)
	prisma.material = material
	# El lomo es la franja alta del cuerpo; el largo va a lo largo de Z.
	var cantidad := 4
	for i in cantidad:
		var avance := (i + 0.5) / cantidad
		var cristal := MeshInstance3D.new()
		cristal.mesh = prisma
		var alto := 0.8 + 0.5 * sin(avance * PI)
		cristal.scale = Vector3(1.0, alto, 1.0)
		cristal.position = Vector3(
			caja.get_center().x,
			caja.end.y * 0.82 + prisma.size.y * alto * 0.4,
			lerpf(caja.position.z + caja.size.z * 0.3, caja.end.z - caja.size.z * 0.1, avance))
		cristal.rotation.x = -0.35
		raiz.add_child(cristal)
	return raiz


static func _caja_del_modelo(modelo: Node3D) -> AABB:
	var caja := AABB()
	var primera := true
	var inversa := modelo.global_transform.affine_inverse()
	for nodo in modelo.find_children("*", "MeshInstance3D", true, false):
		var malla := nodo as MeshInstance3D
		if malla.mesh == null:
			continue
		var parte := inversa * malla.global_transform * malla.mesh.get_aabb()
		caja = parte if primera else caja.merge(parte)
		primera = false
	# Sin el cuello y la cabeza (lo que sobresale hacia adelante) el lomo queda en el medio.
	return caja


# Destellos que suben del animal para distinguirlo de lejos.
static func _agregar_destellos(modelo: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = MATERIAL_DE_CRISTAL_COLOR
	var cubo := BoxMesh.new()
	cubo.size = Vector3.ONE * 0.06
	cubo.material = material
	var destellos := CPUParticles3D.new()
	destellos.name = "Destellos"
	destellos.mesh = cubo
	destellos.amount = 6
	destellos.lifetime = 1.4
	destellos.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	destellos.emission_box_extents = Vector3(0.35, 0.3, 0.5)
	destellos.position.y = 0.9
	destellos.direction = Vector3.UP
	destellos.spread = 20.0
	destellos.gravity = Vector3.ZERO
	destellos.initial_velocity_min = 0.3
	destellos.initial_velocity_max = 0.6
	modelo.add_child(destellos)
