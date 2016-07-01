//
// FragmentShader.glsl
//
#version 300 es

precision mediump float;

in VsOutFsIn {
    vec3 position;
    vec3 normal;
} fsIn;

out vec4 fragColor;

//uniform vec3 ambientIntensity; // Environmental ambient light intensity for each RGB component.
//
//struct LightProperties {
//    vec3 position;      // Light position in eye coordinate space.
//    vec3 rgbIntensity;  // Light intensity for each RGB component.
//};
//uniform LightProperties lightSource;
//
//struct MaterialProperties {
//    vec3 Ka;        // Coefficients of ambient reflectivity for each RGB component.
//    vec3 Kd;        // Coefficients of diffuse reflectivity for each RGB component.
//    float Ks;       // Coefficient of specular reflectivity, uniform across each RGB component.
//    float shininessFactor;   // Specular shininess factor.
//};
//uniform MaterialProperties material;


void main() {
//    vec3 l = normalize(lightSource.position - position); // Direction from fragment to light source.
//    vec3 v = normalize(-position.xyz); // Direction from fragment to viewer (origin - position).
//    vec3 h = normalize(v + l); // Halfway vector.
//    
//    vec3 ambient = ambientIntensity * material.Ka;
//    
//    float n_dot_l = max(dot(normal, l), 0.0);
//    vec3 diffuse = material.Kd * n_dot_l;
//    
//    vec3 specular = vec3(0.0);
//    if (n_dot_l > 0.0) {
//        float n_dot_h = max(dot(normal, h), 0.0);
//        specular = vec3(material.Ks * pow(n_dot_h, material.shininessFactor));
//    }
//    
//    vec3 color = ambient + lightSource.rgbIntensity * (diffuse + specular);
//    
//    fragColor = vec4(color, 1.0);
    
    fragColor = vec4(fsIn.position + fsIn.normal, 1.0f);
}