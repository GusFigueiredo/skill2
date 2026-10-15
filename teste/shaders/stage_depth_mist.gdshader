shader_type canvas_item;
render_mode unshaded;

uniform bool river_theme = false;
// Updated by StageScenery._process so fog stops with the game's pause.
uniform float phase = 0.0;

void fragment() {
	float x = UV.x * 63.0;
	float layers = 0.5
		+ 0.19 * sin(x * 1.9 + UV.y * 4.0 + phase * 0.11)
		+ 0.14 * sin(x * 3.7 - UV.y * 7.0 - phase * 0.09)
		+ 0.08 * sin(x * 7.3 + UV.y * 9.0 + phase * 0.07);
	float bank = exp(-pow((UV.y - 0.39) * 4.2, 2.0));
	float edges = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.62, 1.0, UV.y));
	vec3 tint = river_theme ? vec3(0.43, 0.62, 0.75) : vec3(0.74, 0.81, 0.66);
	float density = river_theme ? 0.072 : 0.057;
	COLOR = vec4(tint, clamp(layers, 0.0, 1.0) * bank * edges * density);
}
