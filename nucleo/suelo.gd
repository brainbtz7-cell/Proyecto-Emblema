class_name Suelo
## Utilidad para saber a qué altura está el suelo en un punto del mundo.

## Capa de física del terreno y las rocas (la número 1, "mundo").
const CAPA_DEL_MUNDO := 1


## Altura del suelo bajo el punto (x, z), o NAN si ahí no hay suelo.
## Necesita un nodo del mundo 3D para poder consultar la física. En "excluir"
## van los cuerpos que no deben contar como suelo (por ejemplo, uno mismo).
static func altura_en(nodo: Node3D, x: float, z: float, excluir: Array[RID] = []) -> float:
	var espacio := nodo.get_world_3d().direct_space_state
	var consulta := PhysicsRayQueryParameters3D.create(
		Vector3(x, 200.0, z), Vector3(x, -200.0, z), CAPA_DEL_MUNDO)
	consulta.exclude = excluir
	var golpe := espacio.intersect_ray(consulta)
	if golpe.is_empty():
		return NAN
	return golpe.position.y
