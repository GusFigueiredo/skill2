shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 radius = TEXTURE_PIXEL_SIZE * 8.0;
	float shadow = texture(TEXTURE, UV).a * 0.24;
	shadow += texture(TEXTURE, UV + vec2(radius.x, 0.0)).a * 0.095;
	shadow += texture(TEXTURE, UV - vec2(radius.x, 0.0)).a * 0.095;
	shadow += texture(TEXTURE, UV + vec2(0.0, radius.y)).a * 0.095;
	shadow += texture(TEXTURE, UV - vec2(0.0, radius.y)).a * 0.095;
	shadow += texture(TEXTURE, UV + radius).a * 0.095;
	shadow += texture(TEXTURE, UV - radius).a * 0.095;
	shadow += texture(TEXTURE, UV + vec2(radius.x, -radius.y)).a * 0.095;
	shadow += texture(TEXTURE, UV + vec2(-radius.x, radius.y)).a * 0.095;
	COLOR = vec4(0.0, 0.008, 0.012, shadow * 0.9);
}
