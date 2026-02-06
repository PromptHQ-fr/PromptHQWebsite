#define GLSLIFY 1

uniform vec2 dataSize;
uniform sampler2D dataTex;

vec2 sampleData(sampler2D tex, vec2 uv, vec2 resolution) {
    vec2 offset = vec2(0.0, 0.0);
    float w = 1.0;
    return w * texture2D(tex, uv + offset / resolution).xy;
}

void main() {
    vec4 data = texture2D(dataTex, gl_FragCoord.xy / dataSize);
    vec2 offsetX = vec2(1.0, 0.0);
    vec2 offsetY = vec2(0.0, 1.0);

    vec2 l = sampleData(dataTex, (gl_FragCoord.xy - offsetX) / dataSize, dataSize);
    vec2 r = sampleData(dataTex, (gl_FragCoord.xy + offsetX) / dataSize, dataSize);
    vec2 t = sampleData(dataTex, (gl_FragCoord.xy - offsetY) / dataSize, dataSize);
    vec2 b = sampleData(dataTex, (gl_FragCoord.xy + offsetY) / dataSize, dataSize);

    float divergence = ((r.x - l.x) + (b.y - t.y)) * 0.5;
    gl_FragColor = vec4(data.xyz, divergence);
}
