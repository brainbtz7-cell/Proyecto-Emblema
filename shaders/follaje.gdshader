// Follaje: hojas pintadas por téxeles en tres tonos, más claras arriba y más
// oscuras abajo. Se mece con el viento. Para no tapar la vista, se llena de
// huecos cuando queda pegado a la cámara y abre una ventana redonda cuando
// se interpone entre la cámara y el protagonista.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/luz_toon.gdshaderinc"

// Dónde está el protagonista (x, y, z) y el radio de la ventana que se abre
// delante de él. Lo publica la cámara; con radio 0 no se abre nada.
global uniform vec4 protagonista;

uniform vec3 color : source_color = vec3(0.3, 0.56, 0.3);
uniform vec3 color_claro : source_color = vec3(0.5, 0.72, 0.34);
uniform vec3 color_oscuro : source_color = vec3(0.2, 0.43, 0.3);
// Tinte propio de cada árbol. Lo elige la arboleda para que no sean todos iguales.
instance uniform vec3 tinte : source_color = vec3(1.0, 1.0, 1.0);
// Tamaño, en metros, de cada téxel pintado sobre las hojas.
uniform float texel = 0.2;

group_uniforms viento;
// Cuánto se desplaza el follaje, en metros.
uniform float fuerza_del_viento = 0.07;
uniform float ritmo_del_viento = 1.3;

group_uniforms camara;
// A menos de esta distancia de la cámara, el follaje se llena de huecos.
uniform float distancia_de_entramado = 4.0;
// Más lejos que esto, el moteado se apaga para que no parpadee.
uniform float alcance_del_moteado = 45.0;

varying vec3 posicion_local;
varying float mira_hacia_arriba;

// Patrón de 4 x 4 píxeles que reparte los huecos de forma pareja.
const int ENTRAMADO[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

float azar(vec3 celda) {
	vec3 p = fract(celda * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	// Los téxeles se miden en metros aunque la copa esté estirada.
	vec3 escala = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	posicion_local = VERTEX * escala;
	mira_hacia_arriba = (MODEL_NORMAL_MATRIX * NORMAL).y;

	// Cada copa se mece entera, con un desfase según dónde está en el mundo.
	vec3 centro = MODEL_MATRIX[3].xyz;
	float fase = TIME * ritmo_del_viento + centro.x * 0.4 + centro.z * 0.3 + centro.y;
	vec3 empuje = vec3(sin(fase), sin(fase * 1.7) * 0.3, cos(fase * 0.8) * 0.6) * fuerza_del_viento;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * empuje;
}

void fragment() {
	float distancia = length(VERTEX);

	// Cuánto se abre el follaje en este píxel: 0 nada, 1 del todo.
	// Las sombras se dibujan siempre enteras.
	if (!IN_SHADOW_PASS) {
		float apertura = 1.0 - distancia / distancia_de_entramado;
		if (protagonista.w > 0.0) {
			vec3 centro = (VIEW_MATRIX * vec4(protagonista.xyz, 1.0)).xyz;
			// Solo cuenta el follaje que está delante del protagonista.
			if (-VERTEX.z < -centro.z - 0.3) {
				// Distancia entre el protagonista y la línea de visión de este píxel.
				float separacion = length(cross(normalize(VERTEX), centro));
				apertura = max(apertura, 1.0 - smoothstep(protagonista.w * 0.45, protagonista.w, separacion));
			}
		}
		int indice = (int(FRAGCOORD.y) % 4) * 4 + int(FRAGCOORD.x) % 4;
		float umbral = (float(ENTRAMADO[indice]) + 0.5) / 16.0;
		if (apertura > umbral) {
			discard;
		}
	}

	float grano = azar(floor(posicion_local / texel));
	float moteado = clamp(1.0 - distancia / alcance_del_moteado, 0.0, 1.0);
	float mezcla = mira_hacia_arriba * 0.5 + 0.5 + (grano - 0.5) * 0.9 * moteado;

	vec3 tono = color;
	if (mezcla > 0.85) {
		tono = color_claro;
	} else if (mezcla < 0.32) {
		tono = color_oscuro;
	}

	ALBEDO = tono * tinte;
	ROUGHNESS = 1.0;
}
