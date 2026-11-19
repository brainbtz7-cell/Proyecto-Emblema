// Material básico del juego: un color plano con iluminación por bandas.
shader_type spatial;
render_mode specular_disabled;

#include "res://shaders/luz_toon.gdshaderinc"

uniform vec3 color : source_color = vec3(0.8, 0.8, 0.8);
// Aclara las zonas en sombra. Sirve en personajes, para que no se pierdan
// cuando quedan a contraluz. En 0 no hace nada.
uniform float luz_propia : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = color * COLOR.rgb;
	ROUGHNESS = 1.0;
	EMISSION = ALBEDO * luz_propia;
}
