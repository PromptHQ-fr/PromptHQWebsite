#define GLSLIFY 1

varying vec2 vUv;
uniform vec3 uScale;
uniform float uTime;
uniform float uScroll;

#define PI 3.14159265359
#define TPI 6.28318530718
#define HPI 1.57079632679

mat2 rotate(float rad) {
    return mat2(cos(rad), sin(rad), -sin(rad), cos(rad));
}

#ifdef IS_CROSS
attribute vec2 instanceId;
#endif

void main(void) {
    vec2 localPos = position.xy;

    #ifdef IS_CROSS
    vec2 loopPos = instanceId.xy;
    loopPos.y = mod(loopPos.y + uScroll * 0.1, 1.0);
    localPos = (loopPos - 0.5) * 1.0;
    #endif

    float theta = localPos.x * PI;
    vec3 roundedPos = vec3(0.0);

    // Cylindrical wrap mode
    #ifdef IS_ROUND
    roundedPos = vec3(
        sin(theta) * 0.5 * uScale.x,
        localPos.y * uScale.y * 1.5,
        -cos(theta) * uScale.x * 0.5
    );
    #endif

    // Flat mode
    #ifdef IS_FLAT
    roundedPos = vec3(localPos.x * uScale.x, localPos.y * uScale.y, 0.0);
    #endif

    vec3 pos = vec3(0.0);

    #ifdef IS_GRID
    pos = roundedPos;
    #endif

    #ifdef IS_CROSS
    pos = position * 0.15;
    #ifdef IS_ROUND
    pos.xz *= rotate(-theta);
    #endif
    pos += roundedPos;
    #endif

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
}
