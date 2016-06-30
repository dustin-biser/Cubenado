#version 300 es

precision mediump float;

in vec3 position;
in vec3 normal;

void main() { 
    gl_Position = vec4(position, 1.0f);
} 