#define GLSLIFY 1

uniform float uTime;
uniform vec2 uScreenResolution;
uniform sampler2D uLogoTex;
uniform sampler2D uPatternCurrent;
uniform sampler2D uPatternNext;
uniform float uLogoDisplayType;
uniform float uScrollPage;
uniform sampler2D uWorks1Tex;
uniform float uWorks1Loaded;
uniform sampler2D uWorks2Tex;
uniform float uWorks2Loaded;
uniform sampler2D uWorksTitleTex;
uniform float uWorksTitleProgress;
uniform float uHideQuad;

varying vec2 vUv;
varying vec2 vGlobalUv;
varying float vSideFace;
varying float vEmitSide;
varying vec2 vScreenUv;
varying float vBlackOut;
varying float vPatternSelect;
varying vec4 vInstanceID;
varying vec2 vWorksTitleUv;
varying vec2 vWorksUv1;
varying vec2 vWorksUv2;
varying float vDisplayWorks;

#define PI 3.14159265359
#define TPI 6.28318530718
#define HPI 1.57079632679

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 hsv2rgb(vec3 hsv) {
    return ((clamp(abs(fract(hsv.x + vec3(0, 2, 1) / 3.) * 6. - 3.) - 1., 0., 1.) - 1.) * hsv.y + 1.) * hsv.z;
}

vec3 rgb2hsv(vec3 rgb) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(rgb.bg, K.wz), vec4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    vec4 q = mix(vec4(p.xyw, rgb.r), vec4(rgb.r, p.yzx), step(p.x, rgb.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

void main(void) {
    vec4 o = vec4(0.0, 0.0, 0.0, 1.0);
    vec2 fragUV = gl_FragCoord.xy / uScreenResolution;
    float wtVisibility = smoothstep(0.1, 0.3, uWorksTitleProgress) * smoothstep(1.0, 0.9, uWorksTitleProgress);

    // Pattern mixing (current/next transition)
    vec4 pat1 = texture2D(uPatternCurrent, vScreenUv);
    vec4 pat2 = texture2D(uPatternNext, vScreenUv);
    o.xyz = mix(pat1.xyz, pat2.xyz, vPatternSelect);
    o.xyz *= (1.0 - wtVisibility * 0.5);
    o.xyz *= (1.0 - vBlackOut);

    // Logo overlay with multiple display modes
    vec2 logoUv = vScreenUv;
    if (uLogoDisplayType == 0.0) {
        // Tiled scrolling
        logoUv = vGlobalUv;
        logoUv -= 0.5;
        logoUv.y *= 1204.0 / 250.0;
        logoUv *= 1.0;
        logoUv += 0.5;
        vec2 tileUv = logoUv.xy * 2.0;
        tileUv.x += sin(floor(tileUv.y) * 3.0 + uTime) * 0.1;
        logoUv = fract(tileUv) * 1.3;
    } else if (uLogoDisplayType == 1.0) {
        // Single tile scroll
        logoUv = vGlobalUv;
        logoUv -= 0.5;
        logoUv.y *= 1204.0 / 250.0;
        logoUv *= 1.1;
        logoUv += 0.5;
        vec2 tileUv = logoUv.xy * 1.0;
        tileUv.x += uTime * 0.05 * sign(floor(tileUv.y));
        logoUv = fract(tileUv) * 1.0;
        if (abs(floor(tileUv.y)) < 0.5) { logoUv = vec2(0.0); }
    } else if (uLogoDisplayType == 2.0) {
        // Vertical scroll per instance
        logoUv = vUv;
        logoUv -= 0.5;
        logoUv.x /= 1204.0 / 250.0;
        logoUv += 0.5;
        logoUv.y -= uTime * 0.5 * vInstanceID.x;
        logoUv.y = fract(logoUv.y);
        logoUv -= 0.5;
        logoUv *= 1.3 + vInstanceID.z * 5.0;
        logoUv += 0.5;
        logoUv.x -= 0.38;
        if (logoUv.x > 0.23 || logoUv.x < 0.00 || logoUv.y > 1.0 || logoUv.y < 0.0 || vInstanceID.y < 0.0) {
            logoUv = vec2(0.0);
        }
    }

    vec4 logo = texture2D(uLogoTex, logoUv);
    float logoW = step(0.5, logo.w) * step(0.0, logoUv.y) * step(logoUv.y, 1.0);
    o.xyz += logoW * 0.2 * (1.0 - wtVisibility);

    // Hide/reveal animation (CRT turn-off effect)
    float hideKv = smoothstep(0.0, 1.0, -vInstanceID.x + uHideQuad * 2.0);
    vec2 flashUv = (vUv - 0.5) * vec2(1.0, 1.0 + hideKv * 50.0);
    o.xyz = mix(o.xyz, (o.xyz + 0.1) * 20.0 * vInstanceID.z, step(0.01, hideKv));
    float turnOff = 1.0;
    turnOff *= step(length(flashUv.y) + hideKv * 0.9, 1.0);
    turnOff *= step(length(flashUv.x) + pow(hideKv, 3.0), 1.0);
    o.xyz *= turnOff;

    // Works title overlay
    vec2 worksTitleUv = vWorksTitleUv;
    vec3 worksTitleCol = texture2D(uWorksTitleTex, worksTitleUv).xyz;
    worksTitleCol *= wtVisibility;

    // Works image blending
    float num = float(WORKS_NUM);
    vec3 t1 = (texture2D(uWorks1Tex, vWorksUv1).xyz) * uWorks1Loaded;
    vec3 t2 = (texture2D(uWorks2Tex, vWorksUv2).xyz) * uWorks2Loaded;
    float blurSize = 0.03;
    vec3 worksCol = mix(t1, t2, smoothstep(fragUV.x - blurSize, fragUV.x + blurSize, uScrollPage * (1.0 + blurSize * 2.0) - blurSize));
    worksCol *= mix(1.0, (random(gl_FragCoord.xy / 1000.0)), 0.1) * 1.0;
    vec3 worksColHSV = rgb2hsv(worksCol);
    worksCol = hsv2rgb(vec3(worksColHSV.x, worksColHSV.y * 2.0, worksColHSV.z));

    o.xyz = mix(o.xyz, worksCol, vDisplayWorks);
    o.w += vDisplayWorks;
    o.w = min(o.w, 1.0);

    // Vignette and halftone dot pattern
    o.xyz *= smoothstep(1.9, 0.1, length(vUv - 0.5));
    o.xyz += worksTitleCol * step(worksTitleUv.x, 1.0) * step(0.01, worksTitleUv.x) * 1.0;

    float dotw = smoothstep(0.5, 0.2, length(fract(vGlobalUv.xy * 1800.0 * vec2(1.0, 1.0) * 0.23) - 0.5));
    dotw = mix(dotw, 1.0, 0.6) * 0.9;
    o.xyz *= dotw;

    // Global vignette
    o.xyz *= smoothstep(0.55, 0.05, length(vGlobalUv - 0.5));

    // Side face emission
    o.xyz *= vSideFace;
    o.xyz += (1.0 - vSideFace) * 0.8 * vEmitSide * (mix(0.05, 1.0, turnOff) + vDisplayWorks);
    o.xyz *= 0.5;

    gl_FragColor = o;
}
