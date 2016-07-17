//
// GroundPlaneVS.glsl
//
#version 300 es
#define ATTRIBUTE_POSITION    0
#define ATTRIBUTE_NORMAL      1

layout(location = ATTRIBUTE_POSITION) in vec3 position;
layout(location = ATTRIBUTE_NORMAL) in vec3 normal;


uniform mat4 modelMatrix;
uniform mat4 viewProjectMatrix;
uniform mat4 shadowMatrix;


out VsOutFsIn {
    highp vec4 shadowCoord;
} vsOut;


void main()
{
    vec4 pos = modelMatrix * vec4(position, 1.0);
    
    // Transform pos to shadow map coordinates
    vsOut.shadowCoord = shadowMatrix * pos;
    
    gl_Position = viewProjectMatrix * pos;
}
