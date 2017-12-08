#version 450

in vec3 position;
in vec2 texcoord;

uniform mat4 MVP;

out vec2 uv;

void main() {
    uv = texcoord;
    gl_Position = MVP * vec4(position, 1.0);
}
