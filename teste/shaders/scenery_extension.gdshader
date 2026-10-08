shader_type canvas_item;
render_mode unshaded;

varying vec4 scenery_tint;

void vertex() {
    scenery_tint = COLOR;
}

// Repeat along the road, extend the edge pixels above and below the art.
void fragment() {
    vec2 uv = vec2(fract(UV.x), clamp(UV.y, TEXTURE_PIXEL_SIZE.y * 0.5, 1.0 - TEXTURE_PIXEL_SIZE.y * 0.5));
    COLOR = scenery_tint * texture(TEXTURE, uv);
}
