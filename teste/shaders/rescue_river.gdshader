shader_type canvas_item;
render_mode unshaded;

varying vec4 river_tint;

void vertex() {
    river_tint = COLOR;
}

void fragment() {
    float river_x = UV.x;
    float river_y = UV.y;
    // Keep the original dry left bank. Beyond the right edge, mirror only
    // the water section so the crossing continues without a hard tile seam.
    if (river_x > 1.0) {
        float water_width = 0.38;
        float repeat_x = mod(river_x - 1.0, water_width * 2.0);
        river_x = 1.0 - (water_width - abs(repeat_x - water_width));
    }
    // The wider shot also sees below the original painting. Continue its
    // roots into a shaded foreground instead of stretching the last pixels.
    if (river_y > 1.0) {
        float roots_height = 0.22;
        float repeat_y = mod(river_y - 1.0, roots_height * 2.0);
        river_y = 1.0 - (roots_height - abs(repeat_y - roots_height));
    }
    vec2 uv = vec2(clamp(river_x, TEXTURE_PIXEL_SIZE.x * 0.5, 1.0 - TEXTURE_PIXEL_SIZE.x * 0.5),
        clamp(river_y, TEXTURE_PIXEL_SIZE.y * 0.5, 1.0 - TEXTURE_PIXEL_SIZE.y * 0.5));
    vec4 paint = texture(TEXTURE, uv);
    if (UV.y > 1.0) {
        paint.rgb = mix(vec3(0.012, 0.022, 0.018), paint.rgb, paint.a);
        paint.a = 1.0;
        paint.rgb *= 1.0 - smoothstep(1.0, 1.3, UV.y) * 0.64;
    }
    COLOR = river_tint * paint;
}
