//
// VertexShader.glsl
//
#version 300 es
#define ATTRIBUTE_POSITION  0
#define ATTRIBUTE_NORMAL    1

layout(std140)
uniform Transforms {
    mat4 modelViewMatrix;
    mat4 mvpMatrix;
    mat4 normalMatrix;
};

layout(location = ATTRIBUTE_POSITION) in vec3 position;
layout(location = ATTRIBUTE_NORMAL) in vec3 normal;

out VsOutFsIn {
    vec4 position;
    vec4 normal;
} vsOut;

void main() {
    vec4 pos = vec4(position, 1.0);
    vec4 n = vec4(normal, 0.0);
    
    // Transform position to EyeSpace.
    vsOut.position = modelViewMatrix * pos;
    
    // Transform normal to EyeSpace.
    vsOut.normal = normalMatrix * n;
    
    gl_Position = mvpMatrix * pos;
}