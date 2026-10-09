shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float surface_y = 0.0;
uniform float surface_x = 0.0;
uniform float phase = 0.0;
varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec4 base = COLOR;
    float wave = sin((world_position.x - surface_x) * 0.09 + phase * 3.0) * 2.0;
    float submerged = smoothstep(surface_y + wave - 2.0, surface_y + wave + 4.0, world_position.y);
    base.rgb = mix(base.rgb, vec3(1.0, 0.88, 0.72), flash);
    base.rgb = mix(base.rgb, base.rgb * vec3(0.65, 0.9, 1.0), submerged);
    base.a *= mix(1.0, 0.6, submerged);
    COLOR = base;
}
