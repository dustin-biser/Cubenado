#version 300 es

uniform Transforms {
    mat4 modelMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
};

in vec3 position;
in vec3 normal;

void main() { 
    gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0f);
}