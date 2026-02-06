#define GLSLIFY 1

varying vec2 vUv;

uniform sampler2D uSceneTex;
uniform sampler2D uNoiseTex;
uniform vec2 uScreenResolution;
uniform float uServiceIn;
uniform float uScreenNoiseScale;
uniform float uVisionRotate;

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 lens_distortion(vec2 r, float alpha) {
    return r * (1.0 - alpha * dot(r, r));
}

void main(void) {
    vec2 geoUV = vUv;
    geoUV.x -= 0.5;
    geoUV.x *= 0.15;
    geoUV.x += 0.5;

    vec2 screenUv = gl_FragCoord.xy / uScreenResolution.xy;
    vec2 uv = mix(geoUV, screenUv, pow(uServiceIn, 0.2));
    vec2 effectUv = geoUV;

    // Noise-based distortion
    vec4 n1 = texture2D(uNoiseTex, effectUv * uScreenNoiseScale);
    vec4 n2 = texture2D(uNoiseTex, effectUv * 0.3 * uScreenNoiseScale + n1.xy * (2.3 + random(screenUv) * 0.2));
    vec3 effectCol = n2.xyz;

    // Scene color with lens distortion
    vec3 sceneCol = vec3(0.0);
    float serviceInInv = (1.0 - uServiceIn);

    for (int i = 0; i < 5; i++) {
        float fi = (float(i) / 5.0);
        vec2 distortedUv = uv;
        distortedUv.xy += (n2.xy - 0.5) * serviceInInv;
        float distortPower = serviceInInv * 5.0 + fi * 0.2 * serviceInInv;
        sceneCol.x += texture2D(uSceneTex, lens_distortion(distortedUv - 0.5, 1.0 * distortPower) + 0.5).x;
        sceneCol.y += texture2D(uSceneTex, lens_distortion(distortedUv - 0.5, 1.05 * distortPower) + 0.5).y;
        sceneCol.z += texture2D(uSceneTex, lens_distortion(distortedUv - 0.5, 1.1 * distortPower) + 0.5).z;
    }
    sceneCol /= 5.0;
    sceneCol *= 1.0 + serviceInInv * 3.0;
    sceneCol *= mix(0.5 + effectCol * 1.0, vec3(1.0), uServiceIn);

    // Warp mask transition
    vec2 warpUv = vUv;
    warpUv.x -= 0.5;
    warpUv.x *= 0.5;
    warpUv.x += 0.5;
    warpUv.y += 0.05;
    float w = smoothstep(0.0, 0.0 + 1.0 * smoothstep(0.0, 1.0, n2.z), -n2.y + uServiceIn * 2.0);

    vec3 outCol = vec3(effectCol.xyz);
    outCol = mix(outCol, sceneCol, w);

    gl_FragColor = vec4(outCol, smoothstep(0.0, 0.1, uVisionRotate));
}
