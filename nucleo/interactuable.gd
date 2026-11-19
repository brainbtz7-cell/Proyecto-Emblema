class_name Interactuable
extends Area3D
## Zona con la que el protagonista puede interactuar cuando está cerca.
##
## Se agrega como hijo de un personaje, un animal o un objeto, con una forma
## de colisión que marque hasta dónde llega. Quien la tenga escucha la señal
## "usado" para reaccionar.

## Se emite cuando el protagonista usa esta zona.
signal usado(jugador: Jugador)

## Capa de física reservada para estas zonas (la número 3, "interactuables").
const CAPA := 4

## Acción que se muestra en pantalla, por ejemplo "Hablar".
@export var accion := "Interactuar"
## Si está apagado, el protagonista lo ignora.
@export var disponible := true


func _ready() -> void:
	collision_layer = CAPA
	collision_mask = 0
	monitoring = false


func usar(jugador: Jugador) -> void:
	usado.emit(jugador)
