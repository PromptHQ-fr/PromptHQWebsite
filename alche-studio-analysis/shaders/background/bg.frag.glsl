#define GLSLIFY 1

varying vec2 vUv;
uniform sampler2D uNoiseTex;
uniform float uNoise;
uniform vec2 uScreenResolution;
uniform vec2 uMousePos;

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec3 o = vec3(0.0);

    // Noise-based coloring with random dithering
    vec4 noise = texture2D(uNoiseTex, vUv * 1.0) + random(vUv) * 0.2;
    float rnd = (0.6 + random(vUv) * 0.4);

    // Color channels from noise with different thresholds
    o.x += smoothstep(0.5, 1.0, noise.x);   // Red - high threshold
    o.y += smoothstep(0.2, 1.0, noise.y);   // Green - medium threshold
    o.z += smoothstep(0.0, 1.0, noise.z);   // Blue - low threshold (most visible)
    o.xyz *= vec3(0.3, 0.4, 0.6) * 0.3;

    // Base dark blue tint
    o += vec3(0.01, 0.025, 0.06);

    // Radial vignette from center
    vec2 cuv = vUv - 0.5;
    float len = length(cuv);
    o.xyz *= smoothstep(0.9, 0.3, len);

    // Additional vignette offset to the left
    o *= smoothstep(1.0, 0.0, length(vUv - 0.5 + vec2(-0.3, 0.0))) * 0.8;

    vec2 fragUv = gl_FragCoord.xy / uScreenResolution.xy;

    gl_FragColor = vec4(o, 1.0);
}
