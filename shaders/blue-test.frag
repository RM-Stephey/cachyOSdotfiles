//
// Example blue light filter shader.
//

#version 300 es

precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    // Make blue channel very low - should look very warm/orange
    pixColor[2] *= 0.3;
    fragColor = pixColor;
}
