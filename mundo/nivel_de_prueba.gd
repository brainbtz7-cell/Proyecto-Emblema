extends Node3D
## Terreno de prueba para ajustar el movimiento, la cámara y el estilo visual.
##
## Es un escenario de trabajo: no representa ningún lugar del canon.

@onready var terreno: Terreno = $Terreno
@onready var jugador: Jugador = $Jugador


func _ready() -> void:
	# Apoya al protagonista sobre el suelo, esté donde esté en la escena.
	var inicio := jugador.global_position
	inicio.y = terreno.altura_en(inicio.x, inicio.z) + 0.1
	jugador.teletransportar(inicio)
