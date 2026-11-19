// Roca: grano de dos tonos, vetas horizontales en las paredes y una cima más
// clara, para que se lea de un vistazo dónde se puede pisar.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/luz_toon.gdshaderinc"

uniform vec3 color : source_color = vec3(0.58, 0.6, 0.65);
uniform vec3 color_de_veta : source_color = vec3(0.47, 0.49, 0.56);
uniform vec3 color_de_cima : source_color = vec3(0.76, 0.76, 0.71);
// Tamaño, en metros, de cada téxel pintado sobre la roca.
uniform float texel = 0.125;
// Cada cuántos téxeles aparece una veta en las paredes.
uniform float separacion_de_vetas = 7.0;

varying vec3 posicion_local;
varying vec3 normal_local;
varying float mira_hacia_arriba;

float azar(vec3 celda) {
	vec3 p = fract(celda * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	posicion_local = VERTEX;
	normal_local = NORMAL;
	mira_hacia_arriba = (MODEL_NORMAL_MATRIX * NORMAL).y;
}

void fragment() {
	// Los téxeles se alinean con el propio objeto, así no se tuercen al girarlo.
	// El 0.999 mete las aristas apenas hacia adentro para que no caigan en la celda vecina.
	vec3 celda = floor(posicion_local * 0.999 / texel - normal_local * 0.5);
	float grano = azar(celda);

	vec3 tono;
	if (mira_hacia_arriba > 0.7) {
		tono = grano > 0.85 ? color : color_de_cima;
	} else {
		tono = grano > 0.8 ? color_de_veta : color;
		// La veta sube o baja un téxel de a tramos para no quedar como una regla.
		float salto = floor(azar(vec3(floor(celda.x / 5.0), 0.0, floor(celda.z / 5.0))) * 2.0);
		if (mod(celda.y + salto, separacion_de_vetas) < 1.0) {
			tono = color_de_veta;
		}
	}

	ALBEDO = tono;
	ROUGHNESS = 1.0;
}
