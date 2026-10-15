shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float x = UV.x * 23.0;
	float ripples = 0.5 + 0.22 * sin(x * 2.7 + UV.y * 5.0 + TIME * 0.12)
		+ 0.13 * sin(x * 6.1 - UV.y * 8.0 - TIME * 0.16)
		+ 0.10 * sin(x * 10.3 + UV.y * 11.0 + TIME * 0.09);
	float low_bank = exp(-pow((UV.y - 0.39) * 3.9, 2.0));
	float edge_fade = smoothstep(0.0, 0.12, UV.y) * (1.0 - smoothstep(0.65, 1.0, UV.y));
	float final_stretch = mix(0.045, 0.09, smoothstep(0.20, 0.85, UV.x));
	COLOR = vec4(0.55, 0.66, 0.64, clamp(ripples, 0.0, 1.0) * low_bank * edge_fade * final_stretch);
}
