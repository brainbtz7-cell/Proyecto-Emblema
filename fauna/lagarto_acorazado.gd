extends CriaturaDePrueba
## La cola segmentada acompaña el paso del lagarto.

var _fase_de_cola := 0.0

@onready var _cola: Node3D = $Modelo/Cola
@onready var _punta: Node3D = $Modelo/Cola/Tramo/Punta


func _animar(delta: float) -> void:
	super._animar(delta)
	var marcha := clampf(Vector2(velocity.x, velocity.z).length() / maxf(velocidad, 0.01), 0.0, 1.0)
	_fase_de_cola += delta * lerpf(1.4, 7.6, marcha)
	var amplitud := lerpf(0.07, 0.28, marcha)
	_cola.rotation.y = sin(_fase_de_cola) * amplitud
	_punta.rotation.y = sin(_fase_de_cola - 1.2) * amplitud * 0.83
