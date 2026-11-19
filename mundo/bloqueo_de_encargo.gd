class_name BloqueoDeEncargo
extends StaticBody3D
## Obstáculo (rocas, escombros) que desaparece al aceptar un encargo.
## Sirve para lugares "antes inaccesibles", como la gruta olvidada.

@export var encargo: Encargo


func _ready() -> void:
	Encargos.cambiado.connect(_actualizar)
	_actualizar()


func _actualizar() -> void:
	var abierto := encargo != null and Encargos.estado_de(encargo) != Encargos.Estado.DISPONIBLE
	visible = not abierto
	process_mode = Node.PROCESS_MODE_DISABLED if abierto else Node.PROCESS_MODE_INHERIT
	for hijo in get_children():
		if hijo is CollisionShape3D:
			hijo.disabled = abierto
