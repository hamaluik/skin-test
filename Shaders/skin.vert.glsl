#version 450

in vec3 position;
in vec2 texcoord;
in vec4 joints;
in vec4 weights;

uniform mat4 MVP;
uniform mat4 jointMatrices[2];

out vec2 uv;

void main() {
    mat4 skinMatrix =   weights.x * jointMatrices[int(joints.x)]
                      + weights.y * jointMatrices[int(joints.y)]
                      + weights.z * jointMatrices[int(joints.z)]
                      + weights.w * jointMatrices[int(joints.w)];

    uv = texcoord;
    gl_Position = MVP * skinMatrix * vec4(position, 1.0);
}
