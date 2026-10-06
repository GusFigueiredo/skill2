shader_type canvas_item;

uniform vec4 opening;

void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	if (UV.x >= opening.x && UV.x <= opening.z && UV.y >= opening.y && UV.y <= opening.w) {
		pixel.a = 0.0;
	}
	COLOR = pixel;
}
