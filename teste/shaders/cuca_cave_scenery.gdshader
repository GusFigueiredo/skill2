shader_type canvas_item;

// Stone receives the cave's even, dim ambient modulation.
uniform bool is_background = false;
varying vec4 painting_tint;

void vertex() {
	painting_tint = COLOR;
}

void fragment() {
	float tile_x = 1.0 - abs(mod(UV.x, 2.0) - 1.0);
	vec2 half_pixel = TEXTURE_PIXEL_SIZE * 0.5;
	// The supplied ground has two stray colored columns on its left edge.
	// Omit them in texture space so mirrored joins never expose a vertical
	// green line; world positions and the tile period remain unchanged.
	float first_texel = TEXTURE_PIXEL_SIZE.x * (is_background ? 0.5 : 2.5);
	float last_texel = 1.0 - half_pixel.x;
	vec2 painting_uv = vec2(mix(first_texel, last_texel, tile_x), clamp(UV.y, half_pixel.y, 1.0 - half_pixel.y));
	vec4 painting = texture(TEXTURE, painting_uv);
	if (is_background) {
		// Recover a little of the source's dark stone detail without making
		// the cave brighter than the fighting plane.
		painting.rgb = pow(max(painting.rgb, vec3(0.0)), vec3(0.94));
		painting.rgb *= vec3(0.91, 1.035, 1.075);
	} else {
		painting.rgb *= vec3(1.06, 1.075, 1.025);
	}
	// A wide camera sees stone dissolving into darkness, never stretched
	// copies of the final row of foreground pixels.
	float lower_shadow = smoothstep(0.91, 1.015, UV.y);
	painting.rgb = mix(painting.rgb, vec3(0.011, 0.018, 0.015), lower_shadow);
	painting.a = mix(painting.a, 1.0, smoothstep(0.96, 1.015, UV.y));
	COLOR = painting * painting_tint;
}
