//
// CubeVS.glsl
//
#version 300 es
#define ATTRIBUTE_POSITION  0
#define ATTRIBUTE_NORMAL    1
#define ATTRIBUTE_INSTANCE_POS 3


layout(std140)
uniform Transforms {
    mat4 modelMatrix;
    mat4 viewMatrix;
    mat4 projectMatrix;
    mat4 normalMatrix;
};

layout(location = ATTRIBUTE_POSITION) in vec3 position;
layout(location = ATTRIBUTE_NORMAL) in vec3 normal;
layout(location = ATTRIBUTE_INSTANCE_POS) in vec3 instancePos;

out VsOutFsIn {
    vec4 position;
    vec4 normal;
} vsOut;

void main() {
    vec4 pos = vec4(position, 1.0);
    vec4 n = vec4(normal, 0.0);
    
    pos = (modelMatrix * pos) + vec4(instancePos, 1.0);
    
    // Transform position to EyeSpace.
    vsOut.position = viewMatrix * pos;
    
    // Transform normal to EyeSpace.
    vsOut.normal = normalMatrix * n;
    
    gl_Position = projectMatrix * pos;
}