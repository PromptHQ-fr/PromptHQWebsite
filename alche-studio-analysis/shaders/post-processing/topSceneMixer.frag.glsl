#define GLSLIFY 1

uniform float uScreenAspectRatio;
uniform float uSPWeight;
uniform vec2 uResolution;
uniform sampler2D uMainSceneTex;
uniform sampler2D uMissionVisionSceneTex;
uniform sampler2D uServiceSceneTex;
uniform sampler2D uNoiseTex;
uniform sampler2D uFluidsTex;
uniform float uVisibleMissionVision;
uniform float uVisibleMissionVisionMotionBlur;
uniform float uVisibleService;

in vec2 vUv;
layout(location = 0) out vec4 outColor;

#define PI 3.14159265359
#define TPI 6.28318530718
#define HPI 1.57079632679

void main(void) {
    vec2 uv = vUv;
    vec2 cuv = uv - 0.5;
    float len = length(cuv);
    vec3 o = vec3(0.0);

    vec4 fluids = texture2D(uFluidsTex, uv);
    float fluidsLength = length(fluids.xy);

    // Main scene with fluid distortion + vignette
    vec3 mainSceneCol = texture(uMainSceneTex, uv + fluids.xy * 0.01).xyz;
    mainSceneCol.xyz *= smoothstep(1.2, 0.0, len);
    mainSceneCol *= 1.0 + fluidsLength * 0.8;
    o += mainSceneCol;

    // Mission/Vision section transition (vertical wipe with motion blur)
    vec3 missionVisionSceneCol = texture(uMissionVisionSceneTex, uv - fluids.xy * 0.01).xyz;
    float range = 1.0 / uResolution.y + abs(uVisibleMissionVisionMotionBlur) * 0.2;
    float missionVisionSelector = 0.0;
    float round = -cos((uv.x - 0.5) * 2.0 * PI / 2.0) * uVisibleMissionVisionMotionBlur * (1.0 - uSPWeight * 0.8);

    if (uVisibleMissionVisionMotionBlur > 0.0) {
        missionVisionSelector = smoothstep(0.0, range, -vUv.y + uVisibleMissionVision * (1.0 + range) + round);
    } else {
        missionVisionSelector = smoothstep(0.0, range, -vUv.y + uVisibleMissionVision * 1.0 + round);
    }

    float missionFluidsThreshold = 0.4 + (uVisibleService * 10.0);
    missionVisionSceneCol.xyz *= 1.0 + length(fluids.xyz) * 0.1 * missionFluidsThreshold;
    missionVisionSceneCol.xyz *= smoothstep(1.5, 0.3, len);
    o = mix(o, missionVisionSceneCol, missionVisionSelector);

    // Service section (hard cut)
    vec3 serviceSceneCol = texture(uServiceSceneTex, uv + fluids.xy * 0.01).xyz;
    serviceSceneCol *= 1.0 + fluidsLength * 0.8;
    serviceSceneCol.xyz *= smoothstep(1.5, 0.3, len);
    o = mix(o.xyz, serviceSceneCol, step(0.9999, uVisibleService));

    outColor = vec4(o.xyz, 1.0);
}
