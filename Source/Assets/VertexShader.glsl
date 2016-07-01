//
// VertexShader.glsl
//
#version 300 es

layout(std140)
uniform Transforms {
    mat4 modelViewMatrix;
    mat4 mvpMatrix;
    mat4 normalMatrix;
};

in vec3 position;
in vec3 normal;

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