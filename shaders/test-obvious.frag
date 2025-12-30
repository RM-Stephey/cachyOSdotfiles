//
// Test shader - VERY obvious red tint to verify shaders work
//

#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 color = texture(tex, v_texcoord);
    
    // Make everything very red - this should be OBVIOUS
    color.r = min(color.r + 0.3, 1.0);
    color.g *= 0.7;
    color.b *= 0.7;
    
    fragColor = color;
}
