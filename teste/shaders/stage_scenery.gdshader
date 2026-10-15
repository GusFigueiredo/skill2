shader_type canvas_item;
render_mode unshaded;

uniform bool river_theme = false;
uniform bool is_background = true;
varying vec4 painting_tint;

void vertex() {
	painting_tint = COLOR;
}

void fragment() {
	// Both sides of each tile sample the same edge pixel. Unlike repeating
	// the original painting, the mirrored join has no abrupt vertical seam.
	float tile_x = 1.0 - abs(mod(UV.x, 2.0) - 1.0);
	vec2 half_pixel = TEXTURE_PIXEL_SIZE * 0.5;
	vec2 art_uv = clamp(vec2(tile_x, UV.y), half_pixel, vec2(1.0) - half_pixel);
	vec4 artwork = texture(TEXTURE, art_uv);
	float luminance = dot(artwork.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 color = artwork.rgb;
	if (is_background) {
		color = mix(vec3(luminance), artwork.rgb, river_theme ? 0.96 : 0.95);
	}
	if (is_background && river_theme) {
		// Moonlight separates the far forest from the wet foreground without
		// flattening the source's deep blue shadows.
		color *= vec3(0.98, 1.02, 1.045);
		color += vec3(0.004, 0.009, 0.016) * (1.0 - luminance);
	} else if (is_background) {
		// Keep the daylight ruins' green and gold palette, with warmer sunlit
		// stone and a trace of cool atmospheric depth in the shadows.
		color *= mix(vec3(0.97, 1.015, 1.025), vec3(1.035, 1.02, 0.97), luminance);
		color += vec3(0.004, 0.008, 0.009) * (1.0 - luminance);
	}
	COLOR = vec4(color, artwork.a) * painting_tint;
}
