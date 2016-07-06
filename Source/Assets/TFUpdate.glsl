//
// TFUpdate.glsl
//
#version 300 es
#define ATTRIBUTE_SLOT_0      0
#define ATTRIBUTE_SLOT_1      1


layout(location = ATTRIBUTE_SLOT_0) in float parametricDist;  // [0,1] Distance along Bezier Curve.
layout(location = ATTRIBUTE_SLOT_1) in float rotationAngle;   // Current rotation angle about orbit.


//// Particle motion will inolve rotation about
//// Bezier curve tangent
//layout(std140)
//uniform BezierCurve {
//    mat4 basisMatrix; // B(t)
//    mat4 derivMatrix; // B'(t), derivative matrix
//} bezierCurve;

// Bezier Curve
uniform mat4 basisMatrix;      // B(t)
uniform mat4 derivMatrix;      // B'(t), derivative matrix padded with extra zeros.

uniform float rotationRadius;      // radius of rotation about Bezier curve.
uniform float rotationalVelocity;  // radians per second.
uniform float parametricVelocity;  // parametric distance along Bezier curve per second.
uniform float deltaTime;           // dt.


out VsOut {
    vec3 position;
    float parametricDist;
    float rotationAngle;
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
// Compute position on Bezier curve, B(t).
vec3 B (
    float t
) {
    float t2 = t*t;
    float t3 = t*t2;
    vec4 position = basisMatrix * vec4(1.0, t, t2, t3);
    return position.xyz;
}


//---------------------------------------------------------------------------------------
// Compute tangent on Bezier curve, B'(t).
vec3 B_tangent (
    float t
) {
    vec4 tangent = (derivMatrix * vec4(1.0, t, t*t, 0.0));
    return normalize(tangent.xyz);
}


//---------------------------------------------------------------------------------------
vec3 normalToCurve (
    float t
) {
    // Compute tangent to curve B'(t), and next tangent B'(t + epsilon).
    vec3 tangent0 = B_tangent(t);
    const float epsilon = 0.001;
    vec3 tangent1 = B_tangent(t+epsilon);
    
    // Axis of rotation.
    vec3 axis = cross(tangent1, tangent0);
    
    // Rotate B'(t) tangent by 90 degrees and return value.
    return rotate_position(tangent0, axis, radians(90.0));
}


//---------------------------------------------------------------------------------------
void main() {
    // Compute current parametric distance along curve.
    float t = clamp(parametricDist + (deltaTime * parametricVelocity), 0.0, 1.0);
    vec3 pointOnCurve = B(t);
    
//    // Compute axis and angle of rotation
//    vec3 axisOfRotation = B_tangent(t);
//    float angle = rotationAngle + (deltaTime * rotationalVelocity);
//    
//    vec3 updatedPosition = pointOnCurve + (rotationRadius * normalToCurve(t));
//    updatedPosition = rotate_position(updatedPosition, axisOfRotation, angle);
//    
//    // Outputs
//    vsOut.position = updatedPosition;
//    vsOut.parametricDist = t;
//    vsOut.rotationAngle = angle;
    
    //TODO: First move particle along curve:
    vsOut.position = pointOnCurve;
    vsOut.parametricDist = t;
    vsOut.rotationAngle = 0.0f;
}