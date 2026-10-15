shader_type canvas_item;
render_mode unshaded;

uniform float phase = 0.0;
uniform vec2 camera_drift = vec2(0.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void fragment() {
    vec2 p = UV * vec2(5.0, 3.0) + vec2(phase * 0.018, -phase * 0.007) + camera_drift;
    float clouds = noise(p) * 0.65 + noise(p * 2.1 + 7.0) * 0.35;
    float low_mist = smoothstep(0.42, 1.0, UV.y) * smoothstep(0.25, 0.85, clouds);
    float edge = smoothstep(0.25, 0.8, length((UV - 0.5) * vec2(1.0, 0.85)));
    vec3 tint = mix(vec3(0.13, 0.22, 0.26), vec3(0.48, 0.64, 0.66), low_mist * 0.8);
    COLOR = vec4(tint, 0.025 + low_mist * 0.038 + edge * 0.06);
}
