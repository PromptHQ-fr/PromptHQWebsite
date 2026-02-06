#define GLSLIFY 1

varying vec2 vUv;
uniform vec2 uGrid;
uniform float uTime;
uniform float uScroll;
uniform sampler2D uFluidsTex;

void main(void) {
    float line = 0.0;
    vec2 gridUv = vUv * uGrid;
    gridUv.y -= uScroll * 1.5;

    float lineThreshold = 0.45;

    #ifndef IS_DARK
        #ifdef IS_THIN_LIGHT
        lineThreshold = 0.44;
        #else
        lineThreshold = 0.46;
        #endif
    #endif

    // Grid lines via fract pattern
    line += smoothstep(lineThreshold, 0.5, abs(fract(gridUv.x) - 0.5));
    line = max(line, smoothstep(lineThreshold, 0.5, abs(fract(gridUv.y) - 0.5)));

    #ifdef IS_DARK
    gl_FragColor = vec4(vec3(0.0), 0.1);
    #else
    // Light grid with fluid distortion
    vec4 fluids = texture2D(uFluidsTex, vUv);
    vec3 col = vec3(1.0);
    col.xy -= fluids.xy * 0.005;
    gl_FragColor = vec4(col, 0.5);
    #endif

    #ifdef IS_THIN_LIGHT
    gl_FragColor.a *= line * 0.05;
    #else
    gl_FragColor.a *= line * 0.2;
    #endif
}
