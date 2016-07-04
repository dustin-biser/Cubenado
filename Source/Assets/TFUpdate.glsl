//
// TFUpdate.glsl
//
#version 300 es
#define ATTRIBUTE_SLOT_0      0
#define ATTRIBUTE_SLOT_1      1
#define ATTRIBUTE_SLOT_2      2

layout(location = ATTRIBUTE_SLOT_0) in vec3 position;
layout(location = ATTRIBUTE_SLOT_1) in vec3 axisOfRotation;
layout(location = ATTRIBUTE_SLOT_2) in float rotationalVelocity;

uniform float deltaTime;
uniform vec3 centerOfRotation;

out VsOut {
    vec3 position;
} vsOut;


//---------------------------------------------------------------------------------------
vec4 quat_from_axis_angle (
    vec3 axis,   // Axis of rotation.
    float angle  // Angle of rotation in radians.
) {
    vec4 q;
    float half_angle = angle * 0.5;
    float sin_half_angle = sin(half_angle);
    q.x = axis.x * sin_half_angle;
    q.y = axis.y * sin_half_angle;
    q.z = axis.z * sin_half_angle;
    q.w = cos(half_angle);
    
    return q;
}

//---------------------------------------------------------------------------------------
vec3 rotate_position (
    vec3 position,
    vec3 axis,   // Axis of rotation.
    float angle  // Angle of rotation in radians.
) {
    vec4 q = quat_from_axis_angle(axis, angle);
    vec3 v = position.xyz;
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

//---------------------------------------------------------------------------------------
void main() {
    //-- Rotate position about centerOfRotation
    vec3 updatedPos = position - centerOfRotation;
    float angle = deltaTime * rotationalVelocity;
    updatedPos = rotate_position(updatedPos, axisOfRotation, angle);
    
    vsOut.position = updatedPos + centerOfRotation;
}