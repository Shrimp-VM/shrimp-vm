shader_type canvas_item;
uniform float speed = 1.0;
uniform float frequency = 3.0;
uniform float angle = 45.0;
uniform float softness = 0.15;
void fragment() {
    float rad = radians(angle);
    vec2 dir = vec2(cos(rad), sin(rad));
    float projection = dot(UV, dir);
    float phase = projection * frequency - TIME * speed;
    float hue = fract(phase);
    vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    float dist = abs(fract(phase) - 0.5) * 2.0;
    float edge = smoothstep(0.0, softness * 2.0, dist);
    rgb *= mix(1.0, edge, 0.3);
    COLOR = vec4(rgb, 1.0);
}