class_name ManiobrasDeCombate
extends RefCounted
## Reglas de la prueba de combate. Las tiradas se reciben ya resueltas.

enum Estilo { USCITA, ACORAZADO, ASALTANTE, CAPITAN }
enum Intencion { GOLPE, CARGA, EMBESTIDA, CORAZA }

const VIDA_PROTAGONISTA := 30
const DANO_NORMAL := 5
const DANO_CERTERO := 7
const UMBRAL_PROTAGONISTA := 6
const UMBRAL_RIVAL := 8
const UMBRAL_EMBESTIDA := 6

const PATRONES := {
	Estilo.USCITA: [Intencion.GOLPE, Intencion.CARGA, Intencion.EMBESTIDA],
	Estilo.ACORAZADO: [Intencion.CORAZA, Intencion.GOLPE, Intencion.CARGA, Intencion.EMBESTIDA],
	Estilo.ASALTANTE: [Intencion.GOLPE, Intencion.CARGA, Intencion.EMBESTIDA, Intencion.CORAZA],
	Estilo.CAPITAN: [Intencion.CARGA, Intencion.EMBESTIDA, Intencion.CORAZA, Intencion.GOLPE, Intencion.GOLPE],
}


static func intencion_de(estilo: Estilo, turno: int) -> Intencion:
	var patron: Array = PATRONES[estilo]
	return patron[(turno - 1) % patron.size()]


static func ataque_propio(tirada: int, certero: bool, intencion: Intencion) -> int:
	if certero:
		return DANO_CERTERO
	if tirada < UMBRAL_PROTAGONISTA:
		return 0
	return floori(DANO_NORMAL * 0.5) if intencion == Intencion.CORAZA else DANO_NORMAL


static func ataque_rival(tirada: int, base: int, guardia: bool, intencion: Intencion) -> int:
	match intencion:
		Intencion.GOLPE:
			if tirada < UMBRAL_RIVAL:
				return 0
			return maxi(1, floori(base / 3.0)) if guardia else base
		Intencion.EMBESTIDA:
			if tirada < UMBRAL_EMBESTIDA:
				return 0
			return maxi(1, floori(base * 0.5)) if guardia else base * 2
	return 0
