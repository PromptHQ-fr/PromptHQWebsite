#define GLSLIFY 1

uniform float uTime;
uniform vec2 dataSize;
uniform sampler2D dataTex;
uniform sampler2D curlTex;
uniform vec2 pointerPos;
uniform vec2 pointerVec;
uniform float pointerSize;
uniform float screenAspect;
uniform vec2 uElmListPos[5];
uniform vec2 uElmListVel[5];
uniform vec2 uElmListSize[5];

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 smapleVelocity(sampler2D tex, vec2 uv, vec2 resolution) {
    vec2 offset = vec2(0.0, 0.0);
    float w = 1.0;
    return w * texture2D(tex, uv + offset / resolution).xy;
}

void main() {
    vec2 uv = gl_FragCoord.xy / dataSize;
    vec2 offsetX = vec2(1.0, 0.0);
    vec2 offsetY = vec2(0.0, 1.0);

    // Vorticity confinement force from curl
    float l = smapleVelocity(curlTex, (gl_FragCoord.xy - offsetX) / dataSize, dataSize).x;
    float r = smapleVelocity(curlTex, (gl_FragCoord.xy + offsetX) / dataSize, dataSize).x;
    float t = smapleVelocity(curlTex, (gl_FragCoord.xy - offsetY) / dataSize, dataSize).x;
    float b = smapleVelocity(curlTex, (gl_FragCoord.xy + offsetY) / dataSize, dataSize).x;
    float c = texture2D(curlTex, uv).x;

    vec2 force = 0.5 * vec2(abs(b) - abs(t), abs(r) - abs(l));
    force /= length(force) + 0.0001;
    force *= 1.0 * c;
    force.y *= -1.0;

    vec4 data = texture2D(dataTex, uv);

    // Mouse/pointer interaction
    vec2 pointerUv = uv;
    pointerUv -= pointerPos;
    if (screenAspect < 1.0) {
        pointerUv.x *= screenAspect;
    } else {
        pointerUv.y /= screenAspect;
    }

    float pv = length(pointerVec);
    pv = smoothstep(0.01, 1.0, pv);
    float pointerW = smoothstep(0.01 + 0.1 * min(0.5, pv), 0.0, length(pointerUv));

    vec2 vel = vec2(0.0, 0.0);
    vec2 velPower = pointerVec * 30.0;
    if (screenAspect < 1.0) {
        velPower.x /= screenAspect;
    } else {
        velPower.y *= screenAspect;
    }
    velPower = min(abs(velPower), vec2(2.0)) * sign(velPower);
    vel += pointerW * velPower;

    gl_FragColor = vec4(data.xy + vel + force, data.zw);
}
