shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float phase = 0.0;
uniform float urgency : hint_range(0.0, 1.0) = 0.0;
uniform float depth : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 offset = vec2(sin(uv.y * 23.0 + phase * 2.8), cos(uv.x * 17.0 - phase * 2.1));
    offset *= depth * depth * 0.009;
    offset += vec2(sin(phase * 1.7), cos(phase * 1.3)) * depth * 0.003;
    vec2 sample_uv = clamp(uv + offset, vec2(0.001), vec2(0.999));
    float blur = depth * depth * 2.2;
    vec3 scene = textureLod(screen_texture, sample_uv, blur).rgb;
    float separation = depth * depth * 0.004;
    scene.r = textureLod(screen_texture, clamp(sample_uv + vec2(separation, 0.0), vec2(0.001), vec2(0.999)), blur).r;
    scene.b = textureLod(screen_texture, clamp(sample_uv - vec2(separation, 0.0), vec2(0.001), vec2(0.999)), blur).b;
    float edge = smoothstep(0.2, 0.68, length((uv - 0.5) * vec2(1.0, 0.85)));
    float beat = pow(0.5 + 0.5 * sin(phase * mix(4.0, 8.0, urgency)), 3.0);
    vec3 warning = mix(vec3(0.22, 0.025, 0.075), vec3(0.005, 0.07, 0.12), depth);
    scene = mix(scene, warning, edge * (urgency * (0.12 + beat * 0.17) + depth * 0.58));
    scene = mix(scene, scene * vec3(0.62, 0.84, 0.95), depth * 0.6);
    COLOR = vec4(scene, 1.0);
}
