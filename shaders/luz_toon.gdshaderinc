// Iluminación por bandas ("toon") que comparten todos los materiales del juego.
// En lugar de un degradado suave, cada luz deja tres tonos planos:
// sombra, media luz y luz plena.

const float UMBRAL_MEDIA_LUZ = 0.03;
const float UMBRAL_LUZ_PLENA = 0.42;

void light() {
	float incidencia = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float banda = 0.5 * step(UMBRAL_MEDIA_LUZ, incidencia) + 0.5 * step(UMBRAL_LUZ_PLENA, incidencia);
	DIFFUSE_LIGHT += banda * LIGHT_COLOR / PI;
}
