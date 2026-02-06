#define GLSLIFY 1

uniform sampler2D uBackBuffer;
uniform sampler2D uThumbnailSceneTex;
uniform sampler2D uLoadingSVGTex;
uniform float uTransition;
uniform float uLoaded;
uniform float uScreenAspectRatio;
uniform float uTime;

in vec2 vUv;
layout(location = 0) out vec4 outColor;

#define PI 3.14159265359
#define TPI 6.28318530718
#define HPI 1.57079632679

void main(void) {
    vec2 uv = vUv;
    vec2 cuv = vUv - 0.5;
    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);

    if (uLoaded < 0.999) {
        // Loading animation: circular reveal with distortion
        if (uScreenAspectRatio > 1.0) {
            cuv.y /= uScreenAspectRatio;
        } else {
            cuv.x *= uScreenAspectRatio;
        }

        float r = smoothstep(0.0, 0.2 + uLoaded * 0.7, -length(cuv) + uLoaded * 1.4);

        vec2 sceneUv = uv;
        sceneUv -= 0.5;
        sceneUv *= (0.5 + uLoaded * 0.5);
        sceneUv += 0.5;
        sceneUv -= (sin(r * PI)) * normalize(cuv) * 0.1;

        vec2 luv = uv - sin(r * PI) * normalize(cuv) * 0.1;

        vec4 backbufferCol = texture(uBackBuffer, sceneUv);
        vec4 thumbnailCol = texture(uThumbnailSceneTex, sceneUv);
        col = backbufferCol;
        col.rgb = mix(col.rgb, thumbnailCol.rgb, thumbnailCol.w * (1.0 - uTransition));

        // Loading SVG overlay
        vec2 loadingUv = luv;
        loadingUv.y = 1.0 - loadingUv.y;
        loadingUv -= 0.5;
        float gradMask = 1.0;
        if (uScreenAspectRatio > 1.0) {
            loadingUv.y /= uScreenAspectRatio;
            loadingUv *= 1.0 / 0.8;
            gradMask = smoothstep(0.5, 0.4, abs(loadingUv.x));
        } else {
            loadingUv.x *= uScreenAspectRatio;
        }
        loadingUv += 0.5;
        vec3 loadingSVG = texture(uLoadingSVGTex, loadingUv).xyz * gradMask;
        col.rgb = mix(loadingSVG, col.rgb, smoothstep(0.0, 0.5, r));
    } else {
        // Normal rendering
        vec4 backbufferCol = texture(uBackBuffer, uv);
        vec4 thumbnailCol = texture(uThumbnailSceneTex, uv);
        col = backbufferCol;
        col.rgb = mix(col.rgb, thumbnailCol.rgb, thumbnailCol.w * (1.0 - uTransition));
    }

    outColor = vec4(col.xyz, 1.0);
}
