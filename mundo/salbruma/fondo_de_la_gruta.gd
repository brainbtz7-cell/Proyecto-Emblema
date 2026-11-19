extends Area3D
## Fondo de la gruta olvidada: al llegar cuenta para el encargo.
##
## PROVISIONAL: el documento deja pendientes el objetivo y la recompensa de
## La gruta olvidada; por ahora alcanza con llegar al fondo.

@export var clave: StringName = &"fondo_de_la_gruta"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(func(cuerpo: Node3D) -> void:
		if cuerpo is Jugador and Encargos.hace_falta(clave):
			Encargos.contar(clave))
