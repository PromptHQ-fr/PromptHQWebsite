#define GLSLIFY 1

uniform float alpha;
uniform float beta;
uniform vec2 dataSize;
uniform sampler2D dataTex;

float sampleData(sampler2D tex, vec2 uv, vec2 resolution) {
    vec2 offset = vec2(0.0, 0.0);
    return texture2D(tex, uv + offset / resolution).z;
}

void main() {
    vec4 data = texture2D(dataTex, gl_FragCoord.xy / dataSize);

    float l = sampleData(dataTex, (gl_FragCoord.xy - vec2(1.0, 0.0)) / dataSize, dataSize);
    float r = sampleData(dataTex, (gl_FragCoord.xy + vec2(1.0, 0.0)) / dataSize, dataSize);
    float t = sampleData(dataTex, (gl_FragCoord.xy - vec2(0.0, 1.0)) / dataSize, dataSize);
    float b = sampleData(dataTex, (gl_FragCoord.xy + vec2(0.0, 1.0)) / dataSize, dataSize);

    float divergence = data.w;
    // Jacobi iteration for pressure solve
    float pressure = ((l + r + t + b) - divergence) * 0.25;
    gl_FragColor = vec4(data.xy, pressure, divergence);
}
