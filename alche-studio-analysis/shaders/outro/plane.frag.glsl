#define GLSLIFY 1

uniform float uTime;
uniform float uVisibility;
uniform vec2 uResolution;
uniform float uAspectRatio;
uniform sampler2D uNoiseTex;

varying vec2 vUv;

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = vUv;
    vec2 centeredUv = (uv - 0.5) * 2.0;

    if (uAspectRatio > 1.0) {
        centeredUv.x *= uAspectRatio;
    } else {
        centeredUv.y /= uAspectRatio;
    }

    vec4 noise = texture2D(uNoiseTex, uv);

    // Dark ambient background coloring from noise
    vec3 color = vec3(0.0);
    color.xyz = vec3(noise.x * 0.3, noise.y * 0.5, noise.z);
    color.xyz *= smoothstep(1.0, 0.1, length(centeredUv)) * 0.3;
    color.xyz *= 1.0 - random(uv) * 0.1;

    gl_FragColor = vec4(color, uVisibility);
}
