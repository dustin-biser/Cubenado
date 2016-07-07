//
// TornadoParticleSimVS.glsl
//
#version 300 es
#define ATTRIBUTE_SLOT_0      0
#define ATTRIBUTE_SLOT_1      1

#define TWO_PI 6.283185

layout(location = ATTRIBUTE_SLOT_0) in float parametricDist;  // [0,1] Distance along Bezier Curve.
layout(location = ATTRIBUTE_SLOT_1) in float rotationAngle;   // Current rotation angle about orbit.


// Particle motion will inolve rotation about Bezier curve tangents
// Bezier Curve
uniform mat4 basisMatrix;      // B(t)
uniform mat4 derivMatrix;      // B'(t), derivative matrix padded with extra zeros.

uniform float deltaTime;           // dt, time delta.
uniform float rotationRadius;      // Radius of rotation about Bezier curve.
uniform float rotationalVelocity;  // Radians per second.
uniform float parametricVelocity;  // Parametric distance along Bezier curve per second.
uniform float particleRandomness;  // [0,1], particle motion randomness factor.
uniform float numActiveParticles;  // Number of active partices.


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
vec3 rotate_position_about_point (
    vec3 position,
    vec3 axis,    // Axis of rotation, assumed noralized.
    float angle,  // Angle of rotation in radians.
    vec3 point    // Center of rotation.
) {
    vec3 newPosition = position - point;
    newPosition = rotate_position(newPosition, axis, angle);
    return newPosition + point;
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
    vec3 tangent = B_tangent(t);
    
    vec3 tangent_cross_x = cross(vec3(1.0f, 0.0, 0.0), tangent);
    vec3 axis = cross(tangent, tangent_cross_x);
    
    // Rotate tangent 90 degrees about new axis and return value.
    return rotate_position(tangent, axis, radians(90.0));
}


//---------------------------------------------------------------------------------------
void main() {
    // Compute new location on curve.
    float newParametricDist = parametricDist + (deltaTime * parametricVelocity);
    float t = (1.0 + sin(newParametricDist * TWO_PI)) * 0.5f;  // Oscillate t between [0,1]
    vec3 pointOnCurve = B(t);
    
    // Compute axis and angle of rotation.
    vec3 axisOfRotation = B_tangent(t);
    float angle = rotationAngle + (deltaTime * rotationalVelocity * (1.0 + particleRandomness));
    
    // Extra distance from curve for debris particles
    float vertexID = float(gl_VertexID);
    float debrisDistance = step(vertexID, numActiveParticles * 0.02 * particleRandomness);
    debrisDistance *= step(0.1, particleRandomness); // No debris particles below 10% particlRandomness
    
    // Increase conicSpread slightly with increase in numActiveParticles.
    float crowdingfactor = 1.0 + numActiveParticles * 0.0005;
    
    // Rotate particle position about pointOnCurve.
    float conicSpread = crowdingfactor * particleRandomness * (t + 0.1) + debrisDistance;
    vec3 updatedPosition = pointOnCurve + ((conicSpread * rotationRadius) * normalToCurve(t));
    updatedPosition =
        rotate_position_about_point(updatedPosition, axisOfRotation, angle, pointOnCurve);
    
    // Outputs
    vsOut.position = updatedPosition;
    vsOut.parametricDist = newParametricDist;
    vsOut.rotationAngle = angle;
}