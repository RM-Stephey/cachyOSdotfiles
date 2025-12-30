//
// Synthwave Vibrance - Boost neon colors while keeping darks deep
// Enhances pink, cyan, purple saturation
//

#version 300 es

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// Vibrance boost (0.0 = none, 0.3 = subtle, 0.6 = intense)
const float vibrance = 0.25;
// Saturation boost for neon colors
const float neonBoost = 1.15;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    // Calculate luminance
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Vibrance - boost saturation of less saturated colors more
    float maxC = max(color.r, max(color.g, color.b));
    float minC = min(color.r, min(color.g, color.b));
    float sat = maxC - minC;
    
    // Apply vibrance (less saturated colors get more boost)
    float vibranceAmount = vibrance * (1.0 - sat);
    color.rgb = mix(vec3(luma), color.rgb, 1.0 + vibranceAmount);
    
    // Boost neon colors (high saturation, bright)
    if (sat > 0.4 && luma > 0.3) {
        // Check if it's a "neon" color (pink, cyan, purple, green)
        bool isPink = color.r > 0.6 && color.b > 0.4 && color.g < 0.5;
        bool isCyan = color.g > 0.6 && color.b > 0.6 && color.r < 0.4;
        bool isPurple = color.r > 0.4 && color.b > 0.6 && color.g < 0.4;
        bool isGreen = color.g > 0.7 && color.r < 0.4 && color.b < 0.5;
        
        if (isPink || isCyan || isPurple || isGreen) {
            color.rgb = mix(vec3(luma), color.rgb, neonBoost);
        }
    }
    
    fragColor = clamp(color, 0.0, 1.0);
}
