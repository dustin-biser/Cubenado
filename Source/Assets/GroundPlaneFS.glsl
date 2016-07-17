//
// GroundPlaneFS.glsl
//
#version 300 es

precision highp float;

uniform mediump sampler2DShadow shadowMap;

in VsOutFsIn {
    vec4 shadowCoord;
} fsIn;


out vec4 fragColor;


void main()
{
    float shadowFactor = textureProj(shadowMap, fsIn.shadowCoord);
    
    vec3 ambient = vec3(0.68);
    
    vec3 groundPlaneColor = vec3(1.0);
    vec3 color = ambient + (shadowFactor * groundPlaneColor);
    
    fragColor = vec4(color, 1.0);
}