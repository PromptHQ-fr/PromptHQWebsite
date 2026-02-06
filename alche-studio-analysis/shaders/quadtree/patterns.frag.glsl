. Animated pattern cycling — use uTime to slowly shift noise UV,
  making the colors flow across tiles like data streams. Some tiles
  scroll horizontally, others vertically, based on vInstanceID.// ============================================
// Pattern 1: Blue/Purple noise-based coloring
// ============================================

// pattern1Frag
uniform sampler2D uNoiseTex;
uniform float uNoise;
uniform float uContour;
uniform float uTheme;
uniform int uPatternType;
varying vec2 vUv;

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec3 o = vec3(0.0);
    vec2 uv = vUv;
    vec4 noise = texture2D(uNoiseTex, uv * 1.0);

    o.x += smoothstep(0.5, 1.0, noise.x);
    o.y += smoothstep(0.2, 1.0, noise.y);
    o.z += smoothstep(0.0, 1.0, noise.z);
    o.xyz *= vec3(0.3, 0.4, 0.6) * 2.0;

    gl_FragColor = vec4(o, 1.0);
}

// ============================================
// Pattern 2: Binary noise grid
// ============================================

// pattern2Frag
/*
uniform sampler2D uNoiseTex;
uniform sampler2D uFluidsTex;
varying vec2 vUv;

void main(void) {
    vec3 o = vec3(0.0);
    vec2 uv = vUv;
    vec4 noise = texture2D(uNoiseTex, uv * 1.0);
    float w = fract(noise.w * 9.0);
    w = step(0.5, w);
    o += w;
    gl_FragColor = vec4(o, 1.0);
}
*/

// ============================================
// Pattern 3: HSV color blending (purple/orange)
// ============================================

// pattern3Frag
/*
uniform sampler2D uNoiseTex;
varying vec2 vUv;

vec3 hsv2rgb(vec3 hsv) { ... }
vec3 rgb2hsv(vec3 rgb) { ... }

void main(void) {
    vec3 o = vec3(0.0);
    vec2 uv = vUv;
    vec4 noise = texture2D(uNoiseTex, uv * 1.0);

    vec3 c = vec3(0.345, 0.098, 0.992) * vec3(0.6, 0.6, 1.0);            // Base purple
    c = mix(c, vec3(0.698, 0.929, 1.0), smoothstep(0.5, 0.9, noise.w));   // Ice blue
    c = mix(c, vec3(0.992, 0.373, 0.047), smoothstep(0.5, 1.0, noise.y)); // Fire orange

    o += vec3(c);
    gl_FragColor = vec4(o, 1.0);
}
*/
