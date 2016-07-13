//
// CubeFS.glsl
//
#version 300 es

precision mediump float;

in VsOutFsIn {
    vec4 position_worldSpace;
    vec4 normal_worldSpace;
} fsIn;

out vec4 fragColor;


layout(std140)
uniform LightSource {
    vec3 position_worldSpace;
    vec3 rgbIntensity;
} lightSource;


layout(std140)
uniform Material {
    vec3 Ka;   // Coefficients of ambient reflectivity for each RGB component.
    vec3 Kd;   // Coefficients of diffuse reflectivity for each RGB component.
} material;


void main() {
    vec3 position = fsIn.position_worldSpace.xyz;
    vec3 normal = normalize(fsIn.normal_worldSpace.xyz);
    
    // Direction from fragment to light source.
    vec3 l = normalize(lightSource.position_worldSpace - position);
    
    const vec3 ambientIntensity = vec3(0.01f, 0.01f, 0.01f);
    vec3 ambient = ambientIntensity * material.Ka;
    
    float n_dot_l = max(dot(normal, l), 0.0);
    vec3 diffuse = material.Kd * n_dot_l;
    
    
    vec3 color = ambient + lightSource.rgbIntensity * diffuse;
    
    fragColor = vec4(color, 1.0);
}