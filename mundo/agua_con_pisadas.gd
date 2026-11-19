extends MeshInstance3D
## Dibuja ondas en la superficie y salpicaduras al entrar, caminar o caer al agua.

const CANTIDAD := 8
const DURACION := 1.12
const DISTANCIA_ENTRE_PISADAS := 0.68
const SALPICADURA := preload("res://efectos/salpicadura.tscn")

@export var jugador: CharacterBody3D
@export var terreno: Terreno

var _material: ShaderMaterial
var _ondas := PackedVector4Array()
var _siguiente := 0
var _activas := 0
var _posicion_anterior := Vector3.ZERO
var _en_el_agua := false
var _recorrido := 0.0
var _lado := 1.0


func _ready() -> void:
	var original := get_active_material(0) as ShaderMaterial
	if not original or not jugador or not terreno:
		set_physics_process(false)
		return
	_material = original.duplicate() as ShaderMaterial
	material_override = _material
	_ondas.resize(CANTIDAD)
	_material.set_shader_parameter(&"ondas", _ondas)
	_posicion_anterior = jugador.global_position


func _physics_process(delta: float) -> void:
	var posicion := jugador.global_position
	var movimiento := posicion - _posicion_anterior
	_posicion_anterior = posicion
	var distancia := Vector2(movimiento.x, movimiento.z).length()
	if distancia > 2.8:
		_en_el_agua = false
		_recorrido = 0.0
		distancia = 0.0

	var nivel := global_position.y
	var umbral := nivel + (0.07 if _en_el_agua else 0.025)
	var agua := posicion.y <= umbral and posicion.y >= nivel - 1.2
	if agua:
		var margen := 0.005 if _en_el_agua else 0.035
		agua = terreno.altura_en(posicion.x, posicion.z) < nivel - margen

	if agua and not _en_el_agua:
		var caida := maxf(0.0, -movimiento.y / delta)
		_emitir(posicion, clampf(0.56 + caida * 0.085, 0.56, 1.3))
	elif agua and jugador.is_on_floor() and distancia > delta * 0.15:
		_recorrido += distancia
		if _recorrido >= DISTANCIA_ENTRE_PISADAS:
			_recorrido -= DISTANCIA_ENTRE_PISADAS
			var al_costado := Vector3(-movimiento.z, 0, movimiento.x).normalized() * 0.12 * _lado
			_lado *= -1.0
			_emitir(posicion + al_costado, clampf(0.35 + distancia / delta * 0.086, 0.36, 0.88))
	elif not agua:
		_recorrido = 0.0
	_en_el_agua = agua

	if _activas <= 0:
		return
	for i in CANTIDAD:
		if _ondas[i].w <= 0.0:
			continue
		_ondas[i].z += delta
		if _ondas[i].z >= DURACION:
			_ondas[i] = Vector4.ZERO
			_activas -= 1
	_material.set_shader_parameter(&"ondas", _ondas)


func _emitir(punto: Vector3, fuerza: float) -> void:
	if _ondas[_siguiente].w <= 0.0:
		_activas += 1
	_ondas[_siguiente] = Vector4(punto.x, punto.z, 0.0, fuerza)
	_siguiente = (_siguiente + 1) % CANTIDAD

	var gotas := SALPICADURA.instantiate() as CPUParticles3D
	gotas.position = to_local(Vector3(punto.x, global_position.y + 0.04, punto.z))
	gotas.initial_velocity_min *= fuerza
	gotas.initial_velocity_max *= fuerza
	add_child(gotas)
