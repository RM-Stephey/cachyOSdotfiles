//
// Neon Glow - Color vibrance only (no bloom artifacts)
//

#version 300 es

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

const float vibrance = 0.25;
const float saturationBoost = 1.15;

void main() {
    vec2 uv = v_texcoord;
    vec4 color = texture(tex, uv);
    
    // === SATURATION BOOST ===
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(vec3(luma), color.rgb, saturationBoost);
    
    // === VIBRANCE (boost less saturated colors more) ===
    float maxC = max(color.r, max(color.g, color.b));
    float minC = min(color.r, min(color.g, color.b));
    float sat = maxC - minC;
    float vibranceAmount = vibrance * (1.0 - sat);
    color.rgb = mix(vec3(luma), color.rgb, 1.0 + vibranceAmount);
    
    fragColor = clamp(color, 0.0, 1.0);
}
