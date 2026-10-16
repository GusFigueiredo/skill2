shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;

void fragment() {
	float drifting = UV.x * 41.0;
	float mist = 0.5 + 0.20 * sin(drifting * 1.9 + UV.y * 5.0 + phase * 0.12)
		+ 0.16 * sin(drifting * 3.7 - UV.y * 8.0 - phase * 0.09)
		+ 0.08 * sin(drifting * 7.1 + UV.y * 12.0 + phase * 0.16);
	float bank = exp(-pow((UV.y - 0.37) * 4.2, 2.0));
	float edges = smoothstep(0.0, 0.11, UV.y) * (1.0 - smoothstep(0.65, 1.0, UV.y));
	COLOR = vec4(0.39, 0.56, 0.46, clamp(mist, 0.0, 1.0) * bank * edges * 0.043);
}
