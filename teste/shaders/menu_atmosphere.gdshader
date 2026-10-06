shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 uv = UV;
	vec2 centered = (uv - 0.5) * vec2(1.0, 0.85);
	float vignette = smoothstep(0.22, 0.65, length(centered)) * 0.45;
	float wave = sin(uv.x * 9.0 + TIME * 0.12) * 0.025;
	float mist = smoothstep(0.55 + wave, 1.15, uv.y) * 0.09;
	float shimmer = 0.5 + 0.5 * sin(TIME * 0.65);
	vec3 tint = mix(vec3(0.005, 0.02, 0.025), vec3(0.22, 0.42, 0.40), mist * 4.0);
	COLOR = vec4(tint, vignette + mist * (0.85 + shimmer * 0.15));
}
