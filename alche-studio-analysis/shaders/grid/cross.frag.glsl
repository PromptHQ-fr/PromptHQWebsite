#define GLSLIFY 1

varying vec2 vUv;

void main(void) {
    float line = 0.0;
    vec2 gridUv = vUv - 0.5;
    float w = 0.08;

    // Cross-hair pattern at grid intersections
    line += smoothstep(w, 0.01, abs(gridUv.x));
    line = max(line, smoothstep(w, w * 0.1, abs(gridUv.y)));

    #ifdef IS_DARK
    gl_FragColor = vec4(vec3(0.0), 0.2);
    #else
    gl_FragColor = vec4(vec3(1.0), 0.3);
        #ifdef IS_THIN_LIGHT
        gl_FragColor.a *= 0.5;
        #endif
    #endif

    gl_FragColor.a *= line;
}
