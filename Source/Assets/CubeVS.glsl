//
// CubeVS.glsl
//
#version 300 es
#define ATTRIBUTE_POSITION    0
#define ATTRIBUTE_NORMAL      1
#define ATTRIBUTE_INSTANCE_0  3
#define ATTRIBUTE_INSTANCE_1  4

layout(location = ATTRIBUTE_POSITION) in vec3 position;
layout(location = ATTRIBUTE_NORMAL) in vec3 normal;
layout(location = ATTRIBUTE_INSTANCE_0) in vec3 instancePos;

// .xyz: Axis of rotation
// .w  : Max angle
layout(location = ATTRIBUTE_INSTANCE_1) in vec4 orientation;


layout(std140)
uniform Transforms {
    mat4 modelMatrix;
    mat4 viewMatrix;
    mat4 projectMatrix;
    mat4 normalMatrix;
};

uniform float cubeRandomness;  // [0,1] degree of randomness.


out VsOutFsIn {
    vec4 position;
    vec4 normal;
} vsOut;


//---------------------------------------------------------------------------------------
vec4 quat_from_axis_angle (
    vec3 axis,   // Axis of rotation, assumed normalized.
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
    vec3 axis,   // Axis of rotation, assumed noralized.
    float angle  // Angle of rotation in radians.
) {
    vec4 q = quat_from_axis_angle(axis, angle);
    vec3 v = position.xyz;
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}


//---------------------------------------------------------------------------------------
void main() {
    // Orient cube in Local Model Space based on cubeRandomness.
    vec3 axis = orientation.xyz;
    float angle = orientation.w * cubeRandomness;
    vec3 orientedPosition = rotate_position(position, axis, angle);
    vec3 orientedNormal = rotate_position(normal, axis, angle);
    
    vec4 pos = vec4(orientedPosition, 1.0);
    vec4 n = vec4(orientedNormal, 0.0);
    
    pos = (modelMatrix * pos) + vec4(instancePos, 1.0);
    
    // Transform position to EyeSpace.
    vsOut.position = viewMatrix * pos;
    
    // Transform normal to EyeSpace.
    vsOut.normal = normalMatrix * n;
    
    gl_Position = projectMatrix * (vsOut.position);
}