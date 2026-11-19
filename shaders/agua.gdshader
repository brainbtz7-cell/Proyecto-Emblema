// Agua: se pinta por téxeles según la profundidad, con espuma que avanza y
// retrocede en la orilla y destellos sobre la superficie.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/luz_toon.gdshaderinc"
#include "res://shaders/datos_terreno.gdshaderinc"

uniform vec3 color_espuma : source_color = vec3(0.94, 0.97, 0.96);
uniform vec3 color_orilla : source_color = vec3(0.6, 0.86, 0.82);
uniform vec3 color_bajo : source_color = vec3(0.36, 0.7, 0.78);
uniform vec3 color_medio : source_color = vec3(0.22, 0.5, 0.74);
uniform vec3 color_hondo : source_color = vec3(0.15, 0.32, 0.63);
uniform vec4 zona_de_humedal = vec4(0.0);
uniform vec3 color_de_humedal : source_color = vec3(0.46, 0.59, 0.40);

// Profundidad, en metros, hasta la que llega cada tono.
uniform float profundidad_orilla = 0.35;
uniform float profundidad_baja = 0.9;
uniform float profundidad_media = 2.0;
// A partir de esta distancia a la cámara ya no se dibujan destellos.
uniform float alcance_de_destellos = 45.0;
// x/z de la pisada, edad en segundos y fuerza (cero si está libre).
uniform vec4 ondas[8];

varying vec3 posicion_mundo;

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 celda = floor(posicion_mundo.xz / TEXEL);
	vec2 centro = (celda + 0.5) * TEXEL;
	float grano = azar(celda);

	float profundidad = posicion_mundo.y - altura_terreno(centro) + (grano - 0.5) * 0.12;

	// La espuma avanza y retrocede con un vaivén lento.
	float vaiven = 0.5 + 0.5 * sin(TIME * 1.4 + grano * 2.0 + (centro.x + centro.y) * 0.15);
	float ancho_de_espuma = 0.05 + 0.1 * vaiven;

	vec3 tono = color_hondo;
	if (profundidad < ancho_de_espuma) {
		tono = color_espuma;
	} else if (profundidad < profundidad_orilla) {
		tono = color_orilla;
	} else if (profundidad < profundidad_baja) {
		tono = color_bajo;
	} else if (profundidad < profundidad_media) {
		tono = color_medio;
	}
	if (zona_de_humedal.z > 0.0) {
		float distancia_humedal = length((centro - zona_de_humedal.xy) / zona_de_humedal.zw);
		float mezcla = (1.0 - smoothstep(0.60, 1.0, distancia_humedal))
			* smoothstep(0.04, 0.38, profundidad);
		tono = mix(tono, color_de_humedal, mezcla * 0.60);
	}

	// Destellos: unos pocos téxeles se encienden y cambian varias veces por segundo.
	float momento = floor(TIME * 3.0);
	float destello = azar(celda + momento * vec2(17.0, 31.0));
	if (destello > 0.992 && profundidad >= ancho_de_espuma && length(VERTEX) < alcance_de_destellos) {
		tono = mix(tono, color_espuma, 0.8);
	}

	if (length(VERTEX) < alcance_de_destellos) {
		float cresta = 0.0;
		float surco = 0.0;
		for (int i = 0; i < 8; i++) {
			vec4 golpe = ondas[i];
			if (golpe.w <= 0.0) {
				continue;
			}
			float edad = golpe.z;
			float distancia = length(centro - golpe.xy);
			float radio = 0.16 + edad * (1.22 + golpe.w * 0.43);
			float presencia = (1.0 - smoothstep(0.20, 1.12, edad)) * golpe.w;
			float frente = 1.0 - smoothstep(0.035, 0.16, abs(distancia - radio));
			float segundo = 1.0 - smoothstep(0.025, 0.13, abs(distancia - max(0.03, radio - 0.29)));
			cresta = max(cresta, presencia * max(frente, segundo * smoothstep(0.14, 0.43, edad) * 0.54));
			surco = max(surco, presencia * (1.0 - smoothstep(0.035, 0.13, abs(distancia - radio - 0.15))));
		}
		tono *= 1.0 - min(surco, 1.0) * 0.19;
		tono = mix(tono, color_espuma, min(cresta, 1.0) * 0.69);
	}

	ALBEDO = tono;
	ROUGHNESS = 1.0;
}
