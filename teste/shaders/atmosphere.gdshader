shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float vignette = smoothstep(0.35, 1.45, length(p * vec2(0.85, 1.0)));
	// Transparent edge shading keeps sprites and attack warnings crisp.
	COLOR = vec4(0.025, 0.045, 0.055, vignette * 0.36);
}
