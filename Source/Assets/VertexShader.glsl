//
// VertexShader.glsl
//
#version 300 es

uniform Transforms {
    mat4 modelMatrix;
    mat4 viewMatrix;
    mat4 projectionMatrix;
};

in vec3 position;
in vec3 normal;

out VsOutFsIn {
    vec3 position;
    vec3 normal;
} vsOut;

void main() { 
    gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0f);
    
    vsOut.position = position;
    vsOut.normal = normal;
}