// Suelo: elige el color de cada téxel según la altura y la pendiente.
// Arena junto al agua, franjas de pasto que siguen el relieve y roca en las
// laderas empinadas.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/luz_toon.gdshaderinc"
#include "res://shaders/datos_terreno.gdshaderinc"

uniform vec3 color_arena_mojada : source_color = vec3(0.72, 0.62, 0.44);
uniform vec3 color_arena : source_color = vec3(0.87, 0.78, 0.56);
uniform vec3 color_pasto_claro : source_color = vec3(0.6, 0.78, 0.42);
uniform vec3 color_pasto : source_color = vec3(0.42, 0.67, 0.38);
uniform vec3 color_pasto_oscuro : source_color = vec3(0.27, 0.52, 0.33);
uniform vec3 color_roca : source_color = vec3(0.56, 0.58, 0.62);
uniform vec3 color_roca_oscura : source_color = vec3(0.42, 0.44, 0.5);
uniform bool dibujar_caminos = false;
uniform sampler2D mascara_camino : filter_linear, repeat_disable;
uniform vec3 color_camino : source_color = vec3(0.67, 0.55, 0.36);
uniform vec3 color_camino_claro : source_color = vec3(0.76, 0.64, 0.45);

// Hasta qué altura (en metros sobre el agua) llega cada zona.
uniform float altura_arena_mojada = 0.12;
uniform float altura_arena = 0.7;
// Alto, en metros, de cada franja de pasto.
uniform float alto_de_franja = 1.1;
// Pendiente a partir de la cual asoma la roca (1.0 = 45 grados).
uniform float pendiente_de_roca = 0.85;

varying vec3 posicion_mundo;

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 celda = floor(posicion_mundo.xz / TEXEL);
	vec2 centro = (celda + 0.5) * TEXEL;
	float grano = azar(celda);

	float altura = altura_terreno(centro);
	float medio_paso = terreno_paso * 0.5;
	vec2 desnivel = vec2(
		altura_terreno(centro + vec2(medio_paso, 0.0)) - altura_terreno(centro - vec2(medio_paso, 0.0)),
		altura_terreno(centro + vec2(0.0, medio_paso)) - altura_terreno(centro - vec2(0.0, medio_paso)));
	float pendiente = length(desnivel) / terreno_paso;

	// El grano mueve un poco los límites para que no queden líneas perfectas.
	float h = altura + (grano - 0.5) * 0.2;

	vec3 tono;
	if (h < altura_arena_mojada) {
		tono = color_arena_mojada;
	} else if (h < altura_arena) {
		tono = grano > 0.92 ? color_arena_mojada : color_arena;
	} else {
		float nivel = (h - altura_arena) / alto_de_franja;
		float franja = floor(nivel);
		tono = franja < 2.0 ? color_pasto_claro : (franja < 5.0 ? color_pasto : color_pasto_oscuro);
		// Una línea más oscura al empezar cada franja marca las curvas de nivel.
		if (fract(nivel) < 0.16 && franja > 0.0) {
			tono = franja < 2.0 ? color_pasto : color_pasto_oscuro;
		}
		if (grano > 0.95) {
			tono = mix(tono, color_pasto_claro, 0.5);
		}
	}
	if (pendiente + (grano - 0.5) * 0.25 > pendiente_de_roca && h > altura_arena_mojada) {
		tono = grano > 0.45 ? color_roca : color_roca_oscura;
	}
	if (dibujar_caminos && altura > 0.02) {
		vec2 posicion_en_mapa = (centro - terreno_origen) / terreno_paso;
		float cobertura = texture(mascara_camino, (posicion_en_mapa + 0.5) / terreno_puntos).r;
		float borde = smoothstep(0.17, 0.78, cobertura + (grano - 0.5) * 0.33);
		tono = mix(tono, grano > 0.68 ? color_camino_claro : color_camino, borde);
	}

	ALBEDO = tono;
	ROUGHNESS = 1.0;
}
