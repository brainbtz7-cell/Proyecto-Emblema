extends Node
## Lleva la cuenta de los encargos: cuáles están en curso y cuánto se avanzó.
##
## Es un autoload: cualquier script puede usar Encargos.aceptar(...),
## Encargos.contar(...) o Encargos.entregar(...).

## Se emite cada vez que un encargo cambia de estado o de avance.
signal cambiado
signal hito(encargo: Encargo, estado: int)

enum Estado {
	DISPONIBLE,  ## Todavía no se aceptó.
	ACTIVO,  ## Aceptado y sin cumplir.
	CUMPLIDO,  ## Objetivo logrado; falta volver a entregarlo.
	COMPLETADO,  ## Entregado.
}

var _estados: Dictionary[StringName, Estado] = {}
var _avances: Dictionary[StringName, int] = {}
var _elementos_contados: Dictionary[StringName, Dictionary] = {}
var _en_curso: Array[Encargo] = []
var _historial: Array[Encargo] = []


func estado_de(encargo: Encargo) -> Estado:
	return _estados.get(encargo.id, Estado.DISPONIBLE)


func avance_de(encargo: Encargo) -> int:
	return _avances.get(encargo.id, 0)


## Encargos aceptados que todavía no se entregaron.
func en_curso() -> Array[Encargo]:
	return _en_curso


## Encargos aceptados en esta partida, en orden de aceptación.
func historial() -> Array[Encargo]:
	return _historial


func puede_aceptar(encargo: Encargo) -> bool:
	if estado_de(encargo) != Estado.DISPONIBLE:
		return false
	for requisito in encargo.requisitos:
		if _estados.get(requisito, Estado.DISPONIBLE) != Estado.COMPLETADO:
			return false
	return true


func aceptar(encargo: Encargo) -> void:
	if not puede_aceptar(encargo):
		return
	_estados[encargo.id] = Estado.ACTIVO
	_avances[encargo.id] = 0
	_en_curso.append(encargo)
	_historial.append(encargo)
	cambiado.emit()
	hito.emit(encargo, Estado.ACTIVO)


## Indica si algún encargo activo todavía necesita lo que cuenta esta clave.
## Sirve para los objetos de misión, que solo aparecen mientras hacen falta.
func hace_falta(clave: StringName) -> bool:
	for encargo in _en_curso:
		if encargo.clave_de_conteo == clave and estado_de(encargo) == Estado.ACTIVO:
			return true
	return false


## Indica si un punto de un encargo ya aportó al contador.
func contado(encargo: Encargo, elemento: StringName) -> bool:
	return _elementos_contados.has(encargo.id) and _elementos_contados[encargo.id].has(elemento)


## Suma uno a cada encargo activo que cuente esta clave. Si se indica un
## elemento, se cuenta una vez aunque se vuelva a cargar la escena.
func contar(clave: StringName, elemento: StringName = &"") -> void:
	var hubo_cambios := false
	var cumplidos: Array[Encargo] = []
	for encargo in _en_curso:
		if encargo.clave_de_conteo != clave or estado_de(encargo) != Estado.ACTIVO:
			continue
		if elemento != &"":
			if contado(encargo, elemento):
				continue
			var elementos: Dictionary = _elementos_contados.get_or_add(encargo.id, {})
			elementos[elemento] = true
		_avances[encargo.id] = avance_de(encargo) + 1
		if _avances[encargo.id] >= encargo.cantidad:
			_estados[encargo.id] = Estado.CUMPLIDO
			cumplidos.append(encargo)
		hubo_cambios = true
	if hubo_cambios:
		cambiado.emit()
	for encargo in cumplidos:
		hito.emit(encargo, Estado.CUMPLIDO)


func entregar(encargo: Encargo) -> void:
	if estado_de(encargo) != Estado.CUMPLIDO:
		return
	_estados[encargo.id] = Estado.COMPLETADO
	_en_curso.erase(encargo)
	cambiado.emit()
	hito.emit(encargo, Estado.COMPLETADO)


## Estado público de los encargos, con recursos identificados por su ID.
func a_diccionario() -> Dictionary:
	var registros: Array[Dictionary] = []
	for encargo in _historial:
		var elementos: Dictionary = _elementos_contados.get(encargo.id, {})
		registros.append({"id": String(encargo.id), "estado": estado_de(encargo),
			"avance": avance_de(encargo), "elementos": elementos.keys()})
	return {"encargos": registros}


## Restaura solamente encargos conocidos; no carga recursos desde el archivo.
func desde_diccionario(datos: Dictionary) -> void:
	var catalogo: Dictionary[String, Encargo] = {}
	for archivo in DirAccess.get_files_at("res://encargos"):
		if archivo.ends_with(".tres") or archivo.ends_with(".tres.remap"):
			var ruta := "res://encargos/" + archivo.trim_suffix(".remap")
			var encargo := load(ruta) as Encargo
			if encargo:
				catalogo[String(encargo.id)] = encargo
	_estados.clear()
	_avances.clear()
	_elementos_contados.clear()
	_en_curso.clear()
	_historial.clear()
	var registros: Variant = datos.get("encargos", [])
	if registros is Array:
		for registro: Variant in registros:
			if not registro is Dictionary:
				continue
			var encargo: Encargo = catalogo.get(str(registro.get("id", "")))
			if encargo == null or _estados.has(encargo.id):
				continue
			var estado := clampi(int(registro.get("estado", 0)), Estado.DISPONIBLE, Estado.COMPLETADO)
			if estado == Estado.DISPONIBLE:
				continue
			var avance := clampi(int(registro.get("avance", 0)), 0, encargo.cantidad)
			if estado >= Estado.CUMPLIDO:
				avance = encargo.cantidad
			elif avance == encargo.cantidad:
				estado = Estado.CUMPLIDO
			_estados[encargo.id] = estado as Estado
			_avances[encargo.id] = avance
			var elementos: Variant = registro.get("elementos", [])
			if elementos is Array:
				var contados: Dictionary = {}
				for elemento: Variant in elementos:
					if elemento is String and not elemento.is_empty():
						contados[StringName(elemento)] = true
				_elementos_contados[encargo.id] = contados
			_historial.append(encargo)
			if estado != Estado.COMPLETADO:
				_en_curso.append(encargo)
	cambiado.emit()
