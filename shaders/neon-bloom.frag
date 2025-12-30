//
// Neon Bloom - Subtle glow effect for bright colors
// Makes neon colors appear to glow/bloom
//

#version 300 es

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// Bloom intensity (0.0 - 1.0)
const float bloomIntensity = 0.15;
const float bloomThreshold = 0.6;
const float bloomSpread = 0.003;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    // Calculate luminance
    float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Sample surrounding pixels for bloom
    vec3 bloom = vec3(0.0);
    float samples = 0.0;
    
    for (float x = -2.0; x <= 2.0; x += 1.0) {
        for (float y = -2.0; y <= 2.0; y += 1.0) {
            vec2 offset = vec2(x, y) * bloomSpread;
            vec4 sample_color = texture(tex, v_texcoord + offset);
            float sample_luma = dot(sample_color.rgb, vec3(0.299, 0.587, 0.114));
            
            // Only bloom bright pixels
            if (sample_luma > bloomThreshold) {
                bloom += sample_color.rgb * (sample_luma - bloomThreshold);
                samples += 1.0;
            }
        }
    }
    
    if (samples > 0.0) {
        bloom /= samples;
    }
    
    // Add bloom to original color
    color.rgb += bloom * bloomIntensity;
    
    fragColor = color;
}
