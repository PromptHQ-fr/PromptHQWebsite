#define GLSLIFY 1

uniform sampler2D uTrnsTex;
uniform sampler2D uNoiseTex;
uniform samplerCube uEnvMap;
uniform vec2 uTrnsWinRes;
uniform float uHideQuad;
uniform float uKvOutVisibility;
uniform float uScrollOutro;
uniform float uRoughness;
uniform float uNoiseScale;
uniform vec3 uMaterialColor;

varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vColor;

#define PI 3.14159265359
#define TPI 6.28318530718
#define HPI 1.57079632679

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

#define SMPLAES 8

// GGX specular distribution
float ggx(float dNH, float roughness) {
    float a2 = roughness * roughness;
    a2 = a2 * a2;
    float dNH2 = dNH * dNH;
    if (dNH2 <= 0.0) return 0.0;
    return a2 / (PI * pow(dNH2 * (a2 - 1.0) + 1.0, 2.0));
}

// Schlick Fresnel approximation
float fresnel(float d) {
    float f0 = 0.1;
    return f0 + (1.0 - f0) * pow(1.0 - d, 5.0);
}

void main(void) {
    vec3 c = vec3(0.0);
    vec2 trnsUv = gl_FragCoord.xy / uTrnsWinRes.xy;

    // Sample noise for roughness variation
    vec4 noise = texture2D(uNoiseTex, vUv * uNoiseScale);
    vec4 noise2 = texture2D(uNoiseTex, vUv * 1.0 + (noise.xy - 0.5) * 2.0);
    float roughness = smoothstep(0.3, 0.8, noise2.y) * uRoughness;

    vec3 normal = normalize(vNormal);

    // Refraction setup (chromatic aberration)
    float refractPower = 0.1;
    vec2 refractNormal = normal.xy * (1.0 - normal.z * 0.7);
    vec2 refractUv = trnsUv;
    vec3 refractCol = vec3(0.0);

    // Multi-sample refraction with chromatic aberration
    for (int i = 0; i < SMPLAES; i++) {
        float slide = 0.005 + random(trnsUv + float(i) * 0.2) * 0.007;
        vec2 roughnessDir = vec2(
            random(trnsUv + float(i) * 0.1) - 0.5,
            random(trnsUv + float(i) * 0.2) - 0.5
        ) * roughness * 0.3;

        // Separate UV for each color channel (chromatic aberration)
        vec2 refractUvR = roughnessDir + refractUv - refractNormal * (refractPower + slide * 1.0);
        vec2 refractUvG = roughnessDir + refractUv - refractNormal * (refractPower + slide * 2.0);
        vec2 refractUvB = roughnessDir + refractUv - refractNormal * (refractPower + slide * 4.0);

        vec3 bg = vec3(
            texture2D(uTrnsTex, refractUvR).x,
            texture2D(uTrnsTex, refractUvG).y,
            texture2D(uTrnsTex, refractUvB).z
        );
        refractCol += bg * 0.9;
    }
    refractCol /= float(SMPLAES);
    c += (refractCol);

    // Specular lighting (GGX)
    vec3 viewDir = normalize(vViewPos);
    vec3 L = normalize(vec3(-1.0, 0.8, -1.0));
    vec3 H = normalize(viewDir + L);
    float dNH = dot(normal, H);
    float spec = ggx(dNH, 0.003 + roughness * 0.4);
    c += spec;

    // Environment reflection with Fresnel
    float F = fresnel(dot(viewDir, normal));
    c += mix(c, textureCube(uEnvMap, reflect(viewDir, normal)).rgb, F * 0.9) * (1.0 - F);

    c *= 1.2;
    c *= uMaterialColor / 255.0;

    gl_FragColor = vec4(c, 1.0);
}
