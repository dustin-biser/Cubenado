//
// TFUpdate.glsl
//
#version 300 es
#define ATTRIBUTE_POSITION  0

layout(location = ATTRIBUTE_POSITION) in vec3 position;

out VsOut {
    vec3 position;
} vsOut;

void main() {
    vec3 delta = vec3(0.0, 0.0, -0.2);
    
    vec3 pos = position + delta;
    if (pos.z < -20.0) {
        pos.z = 0.0;
    }
    vsOut.position = pos;
}