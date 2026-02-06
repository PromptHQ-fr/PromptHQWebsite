#define GLSLIFY 1

attribute vec3 color;

varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewPos;
varying vec3 vColor;

uniform float uTime;
uniform float uHideQuad;
uniform float uVisionRotate;
uniform float uServiceIn;
uniform float uServiceRotate;
uniform float uScreenAspectRatio;

mat2 rotate(float rad) {
    return mat2(cos(rad), sin(rad), -sin(rad), cos(rad));
}

#define PI 3.14159265359
#define TPI 6.28318530718
#define HPI 1.57079632679

void main(void) {
    vec3 pos = position;
    vec3 nml = normal;
    mat2 rot;

    float vis = step(0.95, uHideQuad);

    // Apply rotation from scroll sections (Vision / Service)
    pos.xz *= rotate((uVisionRotate * 0.15 + uServiceRotate * 0.5) * HPI);
    pos.yz *= rotate(uVisionRotate * -0.1 - uServiceRotate * 0.2);

    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    vec4 orthoPos = projectionMatrix * mvPosition;
    orthoPos.xyz /= orthoPos.w;
    orthoPos.w = 1.0;

    vec3 scPos = position;
    #ifdef IS_OUTLINE
    scPos.xyz -= nml * 0.001 * smoothstep(0.0, 0.2, uServiceIn);
    #endif

    // Screen-space position for service section transition
    scPos.xz *= rotate(HPI);
    vec4 screenPos = vec4(
        scPos.x * (20.5 + (1.0 / uScreenAspectRatio * 3.0)),
        scPos.y * (7.0 + uScreenAspectRatio * 8.0) - 0.22,
        orthoPos.z,
        1.0
    );

    // Lerp between 3D and screen-space positions
    vec4 finalPosition = mix(orthoPos, screenPos, uServiceRotate);
    gl_Position = finalPosition;

    vUv = uv;
    vNormal = normalMatrix * nml;
    vViewPos = -mvPosition.xyz;
    vColor = color;
}
