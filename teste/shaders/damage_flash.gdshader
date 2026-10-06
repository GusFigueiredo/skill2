shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	base.rgb = mix(base.rgb, vec3(1.0, 0.88, 0.72), flash);
	COLOR = base;
}
