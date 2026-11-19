// Las raíces quedan fijas. Las puntas siguen el viento y se apartan del protagonista.
shader_type spatial;
render_mode cull_disabled, specular_disabled;

#include "res://shaders/luz_toon.gdshaderinc"

global uniform vec4 protagonista;
global uniform vec4 rival_de_combate;

uniform vec3 color_raiz : source_color = vec3(0.36, 0.47, 0.24);
uniform vec3 color_hoja : source_color = vec3(0.42, 0.55, 0.28);
uniform vec3 color_punta : source_color = vec3(0.60, 0.66, 0.35);
uniform float radio_de_paso = 1.75;
instance uniform float alcance = 91.0;

varying float tono_de_mata;

void vertex() {
	vec3 raiz = MODEL_MATRIX[3].xyz;
	vec2 separacion = raiz.xz - protagonista.xz;
	float distancia = length(separacion);
	float desnivel = abs(raiz.y - protagonista.y + 0.85);
	float paso = (1.0 - smoothstep(0.20, radio_de_paso, distancia))
		* (1.0 - smoothstep(1.0, 2.1, desnivel));
	vec2 afuera = separacion / max(distancia, 0.14);

	float ola = sin(raiz.x * 0.33 + raiz.z * 0.21 + TIME * 2.2);
	float soplo = sin(raiz.x * 0.08 - raiz.z * 0.15 + TIME * 1.05);
	vec2 viento = vec2(0.10 + 0.11 * ola + 0.08 * soplo, 0.035 + 0.08 * ola);

	vec2 empuje = afuera * paso * 1.06 + viento * (1.0 - paso * 0.5);
	float entre_combatientes = 0.0;
	if (rival_de_combate.w > 0.0) {
		vec2 linea_del_duelo = rival_de_combate.xz - protagonista.xz;
		float tramo = clamp(dot(separacion, linea_del_duelo) / max(dot(linea_del_duelo, linea_del_duelo), 0.01), 0.0, 1.0);
		vec2 lateral = separacion - linea_del_duelo * tramo;
		float margen = length(lateral);
		float altura_del_suelo = mix(protagonista.y - 0.85, rival_de_combate.y, tramo);
		entre_combatientes = (1.0 - smoothstep(1.05, rival_de_combate.w, margen))
			* (1.0 - smoothstep(0.65, 1.30, abs(raiz.y - altura_del_suelo)));
		empuje += lateral / max(margen, 0.14) * entre_combatientes * 0.76;
	}
	vec2 eje_x = normalize(MODEL_MATRIX[0].xz);
	vec2 eje_z = normalize(MODEL_MATRIX[2].xz);
	float flexion = UV.y * VERTEX.y;
	VERTEX.xz += vec2(dot(empuje, eje_x), dot(empuje, eje_z)) * flexion;
	VERTEX.y *= 1.0 - paso * UV.y * 0.67;
	VERTEX.y *= 1.0 - entre_combatientes * 0.84;
	float lejos = distance(CAMERA_POSITION_WORLD, raiz);
	VERTEX *= 1.0 - smoothstep(alcance * 0.70, alcance, lejos);
	tono_de_mata = INSTANCE_CUSTOM.r;
}

void fragment() {
	vec3 hoja = mix(color_hoja * 0.81, color_hoja * 1.15, tono_de_mata);
	vec3 tono = mix(color_raiz, hoja, step(0.34, UV.y));
	ALBEDO = mix(tono, color_punta, step(0.76, UV.y) * 0.52);
	NORMAL = (VIEW_MATRIX * vec4(0.15, 0.97, 0.16, 0.0)).xyz;
	ROUGHNESS = 1.0;
}
