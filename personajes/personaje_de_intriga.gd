class_name HabitanteDeIntriga
extends DadorDeEncargos
## Figura provisional que participa en una conversación de la investigación.
##
## Puede estar presente sin aceptar conversación (el líder antes de abrir su
## sector) y puede no ser sólida (el acompañante, la víctima o la nota), para no
## frenar al protagonista ni a la cámara.

## Si bloquea el paso y la cámara cuando está presente.
var solido := true
var conversar: Callable
var _habilitado := false


## [param activo]: si se puede hablar con él. [param presente]: si se ve en el
## mundo; por omisión, lo mismo que [param activo].
func habilitar(activo: bool, charla: Callable, presente: Variant = null) -> void:
	conversar = charla
	_habilitado = activo
	establecer_presencia(activo if presente == null else bool(presente))
	_actualizar()


func establecer_presencia(presente: bool) -> void:
	super(presente)
	if not solido:
		set_deferred("collision_layer", 0)


func _actualizar() -> void:
	_zona.disponible = visible and _habilitado
	_globo.visible = _zona.disponible


func _al_hablar(jugador: Jugador) -> void:
	if not _habilitado or not conversar.is_valid():
		return
	if girar_al_hablar:
		_mirar_a(jugador.global_position)
	await conversar.call(jugador)
