//
// Cyberpunk Composite - Subtle vibrance + edge chromatic aberration
// Single-pass combination for consistent neon aesthetic without overdoing it
//

#version 300 es

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// Vibrance: boost less-saturated colors toward neon
const float vibrance = 0.20;
// Saturation boost for already-neon colors
const float satBoost = 1.10;
// Chromatic aberration amount (very subtle - edges only)
const float aberration = 0.0006;

void main() {
    vec2 uv = v_texcoord;

    // --- Chromatic aberration (edge-weighted) ---
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);
    float aberScale = aberration * dist;
    vec2 dir = normalize(uv - center + 0.0001);

    float r = texture(tex, uv + dir * aberScale).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - dir * aberScale).b;
    float a = texture(tex, uv).a;

    vec4 color = vec4(r, g, b, a);

    // --- Saturation + vibrance ---
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Mild saturation boost
    color.rgb = mix(vec3(luma), color.rgb, satBoost);

    // Vibrance (proportional to how desaturated a pixel is)
    float maxC = max(color.r, max(color.g, color.b));
    float minC = min(color.r, min(color.g, color.b));
    float sat = maxC - minC;
    float vibranceAmt = vibrance * (1.0 - sat);
    color.rgb = mix(vec3(luma), color.rgb, 1.0 + vibranceAmt);

    fragColor = clamp(color, 0.0, 1.0);
}
