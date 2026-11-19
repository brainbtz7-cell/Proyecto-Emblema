class_name Manada
extends Node3D
## Reparte animales por una zona y repone los que falten.
##
## La fauna se repone cuando el protagonista vuelve a un poblado
## (ver mundo/poblado.gd).

## Escena del animal que aparece.
@export var animal: PackedScene
## Cuántos animales mantiene en la zona.
@export var cantidad := 4
## Radio de la zona, en metros.
@export var radio := 9.0
## Distancia mínima al resto del grupo al aparecer.
@export var separacion := 0.0
## Solo aparecen donde el suelo esté entre estas dos alturas, en metros.
@export var altura_minima := -0.25
@export var altura_maxima := 2.0


func _ready() -> void:
	add_to_group("manadas")
	# El suelo tarda un par de pasos de física en poder consultarse.
	await get_tree().physics_frame
	await get_tree().physics_frame
	reponer()


## Hace aparecer los animales que falten hasta llegar a la cantidad.
func reponer() -> void:
	if animal == null:
		return
	for n in cantidad - _vivos():
		_crear_uno()


func _vivos() -> int:
	var total := 0
	for hijo in get_children():
		if hijo is CriaturaDePrueba and not hijo.is_queued_for_deletion():
			total += 1
	return total


func _crear_uno() -> void:
	# Prueba lugares al azar hasta dar con uno que tenga suelo a buena altura.
	for intento in 60:
		var angulo := randf() * TAU
		var distancia := sqrt(randf()) * radio
		var x := global_position.x + cos(angulo) * distancia
		var z := global_position.z + sin(angulo) * distancia
		var altura := Suelo.altura_en(self, x, z)
		if is_nan(altura) or altura < altura_minima or altura > altura_maxima:
			continue
		var sitio := Vector3(x, altura + 0.05, z)
		if separacion > 0.0 and not _hay_espacio(sitio):
			continue
		var nuevo := animal.instantiate() as Node3D
		nuevo.position = to_local(sitio)
		nuevo.rotation.y = randf() * TAU
		add_child(nuevo)
		return


func _hay_espacio(sitio: Vector3) -> bool:
	for criatura in get_children():
		if criatura is CriaturaDePrueba and not criatura.is_queued_for_deletion():
			var distancia := Vector2(criatura.global_position.x - sitio.x, criatura.global_position.z - sitio.z)
			if distancia.length_squared() < separacion * separacion:
				return false
	return true
