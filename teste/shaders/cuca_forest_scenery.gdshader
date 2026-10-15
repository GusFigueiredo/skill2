shader_type canvas_item;
render_mode unshaded;

uniform vec2 art_origin = vec2(0.0);
uniform vec2 art_size = vec2(1672.0, 941.0);
uniform float art_scale = 0.56;
uniform bool is_background = false;
varying vec4 painting_tint;

void vertex() {
	painting_tint = COLOR;
}

void fragment() {
	// Mirrored tiles meet at the very same edge pixel, removing the hard
	// vertical cuts produced by repeating these hand-painted source images.
	float horizontal = 1.0 - abs(mod(UV.x, 2.0) - 1.0);
	vec2 sample_uv = vec2(horizontal, clamp(UV.y, TEXTURE_PIXEL_SIZE.y * 0.5, 1.0 - TEXTURE_PIXEL_SIZE.y * 0.5));
	vec4 artwork = texture(TEXTURE, sample_uv);
	float world_x = art_origin.x + UV.x * art_size.x * art_scale;
	float approach = smoothstep(1100.0, 4250.0, world_x);
	vec3 forest_tint = mix(vec3(1.00, 1.025, 0.98), vec3(0.76, 0.87, 0.84), approach * 0.74);
	if (is_background) {
		forest_tint *= vec3(0.91, 0.98, 1.01);
	} else {
		// A wider cinematic camera can see beyond the foreground painting.
		// Let its roots dissolve into shadow instead of stretching the final
		// row of pixels into long vertical stripes below the scene.
		float foreground_shadow = smoothstep(0.88, 1.01, UV.y);
		artwork.rgb = mix(artwork.rgb, vec3(0.018, 0.033, 0.022), foreground_shadow);
		artwork.a = mix(artwork.a, 1.0, smoothstep(0.94, 1.01, UV.y));
	}
	COLOR = artwork * painting_tint * vec4(forest_tint, 1.0);
}
