// Cielo: un degradado en escalones, del horizonte claro al cenit más azul.
shader_type sky;

uniform vec3 color_cenit : source_color = vec3(0.33, 0.58, 0.84);
uniform vec3 color_horizonte : source_color = vec3(0.82, 0.91, 0.94);
// Cantidad de escalones del degradado.
uniform float escalones = 10.0;

void sky() {
	float altura = sqrt(clamp(EYEDIR.y, 0.0, 1.0));
	altura = floor(altura * escalones) / escalones;
	COLOR = mix(color_horizonte, color_cenit, altura);
}
