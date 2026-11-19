// Contorno: dibuja el objeto otra vez, apenas más grande, de un color oscuro
// y solo por sus caras traseras. Asoma por los bordes y deja una línea.
// Se usa como "Next Pass" de otro material.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec3 color : source_color = vec3(0.07, 0.07, 0.14);
// Grosor de la línea, en píxeles del juego.
uniform float grosor = 1.0;

void vertex() {
	// El borde se empuja en pantalla, no en el mundo: así la línea mide lo
	// mismo de cerca que de lejos.
	vec4 posicion = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 normal = mat3(PROJECTION_MATRIX) * (MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec2 direccion = normal.xy / max(length(normal.xy), 0.0001);
	posicion.xy += direccion / VIEWPORT_SIZE * 2.0 * grosor * posicion.w;
	POSITION = posicion;
}

void fragment() {
	ALBEDO = color;
}
