#version 450

in vec2 uv;

uniform sampler2D tex;

out vec4 fragColour;

void main() {
    fragColour = texture(tex, uv);
}
