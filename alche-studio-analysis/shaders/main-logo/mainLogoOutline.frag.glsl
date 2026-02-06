#define GLSLIFY 1

varying vec2 vUv;

void main(void) {
    #ifdef IS_BASE
    // Semi-transparent light gray base
    gl_FragColor = vec4(vec3(0.843, 0.859, 0.863), 0.0);
    #endif

    #ifdef IS_OUTLINE
    // Solid white outline
    gl_FragColor = vec4(vec3(1.0), 1.0);
    #endif
}
