extends CPUParticles3D
## Efecto de partículas de un solo uso: se emite al aparecer y luego se borra.


func _ready() -> void:
	finished.connect(queue_free)
	emitting = true
