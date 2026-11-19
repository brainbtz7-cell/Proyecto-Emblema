// Datos del terreno que terreno.gd publica para todos los shaders.
// Con ellos, el suelo y el agua saben qué altura hay en cada punto del mundo.

global uniform sampler2D terreno_mapa_altura : filter_linear, repeat_disable;
global uniform vec2 terreno_origen;
global uniform float terreno_paso;
global uniform float terreno_puntos;

// Tamaño, en metros, de cada "téxel" pintado sobre el mundo. El color se
// decide una vez por téxel, como si el suelo tuviera una textura de pixel art.
const float TEXEL = 0.125;

// Altura del terreno, en metros, en un punto del mundo (x, z).
float altura_terreno(vec2 xz) {
	vec2 uv = ((xz - terreno_origen) / terreno_paso + 0.5) / terreno_puntos;
	return texture(terreno_mapa_altura, clamp(uv, 0.0, 1.0)).r;
}

// Número pseudoaleatorio entre 0 y 1, siempre igual para la misma celda.
float azar(vec2 celda) {
	vec3 p = fract(vec3(celda.xyx) * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
