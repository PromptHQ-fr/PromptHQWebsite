#define GLSLIFY 1

uniform sampler2D dataTex;
uniform vec2 dataSize;
uniform float curl;

vec2 sampleData(sampler2D tex, vec2 uv, vec2 res) {
    vec2 offset = vec2(0.0, 0.0);
    float w = 1.0;
    return w * texture2D(tex, uv + offset / res).xy;
}

void main() {
    vec2 uv = gl_FragCoord.xy / dataSize;
    vec2 offsetX = vec2(1.0, 0.0);
    vec2 offsetY = vec2(0.0, 1.0);

    // Compute curl of velocity field
    float l = sampleData(dataTex, (gl_FragCoord.xy - offsetX) / dataSize, dataSize).y;
    float r = sampleData(dataTex, (gl_FragCoord.xy + offsetX) / dataSize, dataSize).y;
    float t = sampleData(dataTex, (gl_FragCoord.xy - offsetY) / dataSize, dataSize).x;
    float b = sampleData(dataTex, (gl_FragCoord.xy + offsetY) / dataSize, dataSize).x;

    float c = (r - l - b + t);
    gl_FragColor = vec4(curl * c, 0.0, 0.0, 1.0);
}
