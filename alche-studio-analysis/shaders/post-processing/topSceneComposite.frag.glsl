#define GLSLIFY 1

uniform sampler2D uBackBuffer;
uniform sampler2D uBloomTexture[4];
uniform float cameraNear;
uniform float cameraFar;
uniform sampler2D uFluidsTex;
uniform sampler2D uNotFoundSceneTex;
uniform float uNotFoundVisibility;
uniform sampler2D uAsciiTexture;
uniform float uScreenAspectRatio;
uniform float uSPWeight;

in vec2 vUv;
layout(location = 0) out vec4 outColor;

vec2 lens_distortion(vec2 r, float alpha) {
    return r * (1.0 - alpha * dot(r, r));
}

vec3 filmic(vec3 x) {
    vec3 X = max(vec3(0.0), x - 0.004);
    vec3 result = (X * (6.2 * X + 0.5)) / (X * (6.2 * X + 1.7) + 0.06);
    return pow(result, vec3(2.2));
}

void main(void) {
    vec3 col = vec3(0.0, 0.0, 0.0);
    vec2 uv = vUv;
    vec2 cuv = uv - 0.5;
    float len = length(cuv);

    // Fluid distortion on UV
    vec4 fluids = texture2D(uFluidsTex, uv);
    uv -= (fluids.xy) * 0.001;
    col = texture(uBackBuffer, uv).xyz;

    // ASCII art overlay for 404 page
    vec2 res = vec2(70.0) * (1.0 - uSPWeight * 0.3);
    if (uScreenAspectRatio > 1.0) {
        res.x *= uScreenAspectRatio;
    } else {
        res.y *= 1.0 / uScreenAspectRatio;
    }

    vec2 notFoundUv = floor(uv * res) / res;
    vec2 asciiUv = fract(uv * res);
    vec4 notFoundColor = texture(uNotFoundSceneTex, notFoundUv);
    vec4 asciiFluid = texture2D(uFluidsTex, notFoundUv);
    float asciiLevel = notFoundColor.x + length(asciiFluid.xy) * 0.2;
    asciiLevel = min(1.0, asciiLevel * 1.9);
    asciiUv.y = 1.0 - asciiUv.y;
    asciiUv.x += 15.0 - (floor(asciiLevel * 15.0));
    asciiUv.x /= 16.0;
    vec4 asciiColor = texture(uAsciiTexture, asciiUv);
    col *= 1.0 - uNotFoundVisibility * 0.6;
    col = mix(col, vec3(1.0), asciiColor.x * uNotFoundVisibility * 0.5);

    // Add bloom layers
    #pragma unroll_loop_start
    for (int i = 0; i < 3; i++) {
        col += texture(uBloomTexture[UNROLLED_LOOP_INDEX], uv).xyz
             * (0.5 + float(UNROLLED_LOOP_INDEX) * 0.5) * 0.15;
    }
    #pragma unroll_loop_end

    col.xyz *= 1.3;
    outColor = vec4(col, 1.0);
}
