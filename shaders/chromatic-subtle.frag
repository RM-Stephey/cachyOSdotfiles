//
// Chromatic Aberration Subtle - Very slight RGB split at edges
// Gives that "holographic" neon feel
//

#version 300 es

precision highp float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

// Aberration amount (0.001 = subtle, 0.003 = noticeable)
const float aberrationAmount = 0.0008;

void main() {
    vec2 uv = v_texcoord;
    
    // Distance from center for edge-based effect
    vec2 center = vec2(0.5);
    float dist = distance(uv, center);
    
    // Scale aberration by distance from center
    float aberration = aberrationAmount * dist;
    
    // Direction from center
    vec2 dir = normalize(uv - center);
    
    // Sample RGB channels with slight offset
    float r = texture(tex, uv + dir * aberration).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - dir * aberration).b;
    float a = texture(tex, uv).a;
    
    fragColor = vec4(r, g, b, a);
}
