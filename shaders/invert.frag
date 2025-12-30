#version 300 es
precision mediump float;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 color = texture(tex, v_texcoord);
    // Invert colors - VERY obvious
    fragColor = vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a);
}
