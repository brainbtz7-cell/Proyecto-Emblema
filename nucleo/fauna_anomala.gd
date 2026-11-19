class_name FaunaAnomala
extends Object
## Reglas de la Fauna Anómala del Documento Maestro (apartado 4.3).
##
## - Cada animal que aparece al regenerarse una SubZona tiene, por separado,
##   un 0,25 % de probabilidad de ser Anómalo (en promedio, 1 de cada 400).
## - Al cazar uno se obtiene una Ficha Anómala, que queda registrada en la
##   colección "Fauna Anómala".
## - Cada 10 fichas se podrán canjear por un objeto que sube un atributo al
##   azar en 1 punto. PENDIENTE: el objeto, los atributos, la experiencia y
##   los objetos ordinarios todavía no existen en el juego, así que el canje
##   y las recompensas dobles no están implementados.
##
## Todo es estático: se usa como FaunaAnomala.tirar(), sin autoload.

## Probabilidad de que un animal aparezca como Anómalo.
const PROBABILIDAD := 0.0025
## Fichas necesarias para un canje.
const FICHAS_POR_CANJE := 10
const VERSION_DE_DATOS := 1

## Probabilidad en uso. Se puede subir para probar: al lanzar el juego con
## el argumento "--anomalia-forzada" vale 1 (todos los animales son Anómalos).
static var probabilidad := PROBABILIDAD
## Fichas Anómalas que tiene el protagonista.
static var fichas := 0
## Cuántos Anómalos de cada especie se cazaron: {"Uscita": 2, ...}.
static var coleccion: Dictionary[String, int] = {}

static var _revisado_el_argumento := false


## Decide si el animal que está por aparecer será Anómalo.
static func tirar() -> bool:
	if not _revisado_el_argumento:
		_revisado_el_argumento = true
		if "--anomalia-forzada" in OS.get_cmdline_user_args():
			probabilidad = 1.0
	return randf() < probabilidad


## Anota la caza de un Anómalo y entrega su ficha.
static func registrar_caza(especie: String) -> void:
	fichas += 1
	coleccion[especie] = coleccion.get(especie, 0) + 1


## Canjes que se podrían hacer con las fichas actuales.
static func canjes_disponibles() -> int:
	return fichas / FICHAS_POR_CANJE


## Datos para el guardado de partida.
static func a_diccionario() -> Dictionary:
	return {"version": VERSION_DE_DATOS, "fichas": fichas, "coleccion": coleccion.duplicate()}


## Restaura los datos de una partida guardada.
static func desde_diccionario(datos: Dictionary) -> void:
	fichas = int(datos.get("fichas", 0))
	coleccion.clear()
	var guardada: Dictionary = datos.get("coleccion", {})
	for especie in guardada:
		coleccion[String(especie)] = int(guardada[especie])
