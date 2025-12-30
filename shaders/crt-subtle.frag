//
// CRT Subtle - Very light scanlines and slight curvature
// Retro feel without being distracting
//

#version 300 es

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// Scanline intensity (0.0 = none, 0.1 = subtle, 0.3 = visible)
const float scanlineIntensity = 0.06;
const float scanlineCount = 800.0;

// Vignette (darkening at edges)
const float vignetteIntensity = 0.15;

void main() {
    vec2 uv = v_texcoord;
    
    // Subtle vignette
    vec2 vignetteUV = uv * (1.0 - uv);
    float vignette = vignetteUV.x * vignetteUV.y * 15.0;
    vignette = pow(vignette, vignetteIntensity);
    
    vec4 color = texture(tex, uv);
    
    // Subtle scanlines
    float scanline = sin(uv.y * scanlineCount * 3.14159) * 0.5 + 0.5;
    scanline = 1.0 - (scanlineIntensity * (1.0 - scanline));
    
    color.rgb *= scanline;
    color.rgb *= vignette;
    
    fragColor = color;
}
