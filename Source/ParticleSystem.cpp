//
//  ParticleSystem.cpp
//

#import "ParticleSystem.hpp"
using glm::vec3;

#import <vector>
using std::vector;

#import <cmath>
using std::sin;

#import <algorithm>
using std::min;

#import <glm/gtx/rotate_vector.hpp>
using glm::rotateY;


#import "ShaderProgram.hpp"
#import "AssetDirectory.hpp"
#import "VertexAttributeDefines.h"
#import "NormRand.hpp"


class ParticleSystemImpl {
private:
    friend class ParticleSystem;
    
//-- Members:
    uint m_numActiveParticles;
    uint m_maxParticles;
    float m_particleRandomness;
    
    const AssetDirectory & m_assetDirectory;
    
    ShaderProgram m_shaderProgram_TFUpdate;
    struct UniformLocations {
        GLint basisMatrix;
        GLint derivMatrix;
        GLint rotationRadius;
        GLint rotationalVelocity;
        GLint parametricVelocity;
        GLint deltaTime;
        GLint particleRandomness;
        GLint numActiveParticles;
    };
    UniformLocations m_uniformLocations;
    
    
    struct ParticleData {
        glm::vec3 position;
        float parametricDist;
        float rotationAngle;
    };
    
    struct ControlPointMotion {
        glm::vec3 centerOfRotation;
        float radius;
        float angle;
        float rotationSpeed;
    };
    
    struct BezierCurve {
        glm::mat4 basisMatrix; // B(t)
        glm::mat4 derivMatrix; // B'(t), derivative matrix
        
        // Control Points
        glm::vec3 p0;
        glm::vec3 p1;
        glm::vec3 p2;
        glm::vec3 p3;
        
        // Control Point Motion
        ControlPointMotion p0_motion;
        ControlPointMotion p1_motion;
        ControlPointMotion p2_motion;
        ControlPointMotion p3_motion;
    };
    BezierCurve m_tornadoCurve;
    
    
    // Transform Feedback source/destination buffers.
    // For holding interleaved vertex attributes
    struct TransformFeedbackBuffers {
        GLuint sourceVbo;
        GLuint destVbo;
    };
    TransformFeedbackBuffers m_TFBuffers;
    
    GLuint m_vao_TFSource;
    GLuint m_vao_TFDest;
    
    
    
//-- Methods:
    ParticleSystemImpl (
        const AssetDirectory & assetDirectory,
        uint numActiveParticles,
        uint maxParticles,
        float particleRandomness
    );
    
    void loadShaders();
    
    void initTransformFeedbackBuffers();
    
    void setupVertexAttribMappings();
    
    void setStaticUniformData();
    
    void setNumActiveParticles (
        uint numActiveParticles
    );
    
    void update (
        double secondsSinceLastUpdate
    );
    
    void updateUniforms (
        double secondsSinceLastUpdate
    );
    
    void initTornadoCurve();
    
    void updateBezierMatricesFromControlPoint();
    
    VertexAttributeDescriptor getVertexDescriptorForParticlePositions() const;
    
    void updateTornadoCurveMotion (
        double secondsSinceLastUpdate
    );
    
    void updateControlPointPosition (
        glm::vec3 & pointPosition,
        ControlPointMotion & pointMotion,
        float secondsSinceLastUpdate
    );
    
}; // end class ParticleSystemImpl


//---------------------------------------------------------------------------------------
ParticleSystemImpl::ParticleSystemImpl (
    const AssetDirectory & assetDirectory,
    uint numActiveParticles,
    uint maxParticles,
    float particleRandomness
)
    : m_assetDirectory(assetDirectory),
      m_numActiveParticles(numActiveParticles),
      m_maxParticles(maxParticles),
      m_particleRandomness(particleRandomness)
{
    loadShaders();
    
    initTransformFeedbackBuffers();
    
    setupVertexAttribMappings();
    
    setStaticUniformData();
    
    initTornadoCurve();
}

//---------------------------------------------------------------------------------------
ParticleSystem::ParticleSystem (
    const AssetDirectory & assetDirectory,
    uint numActiveParticles,
    uint maxParticles,
    float particleRandomness
) {
    impl = new ParticleSystemImpl(assetDirectory, numActiveParticles, maxParticles,
                                  particleRandomness);
}

//---------------------------------------------------------------------------------------
ParticleSystem::~ParticleSystem()
{
    delete impl;
    impl = nullptr;
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::loadShaders() {
    m_shaderProgram_TFUpdate.generateProgramObject();
    m_shaderProgram_TFUpdate.attachVertexShader(m_assetDirectory.at("TornadoParticleSimVS.glsl"));
    m_shaderProgram_TFUpdate.attachFragmentShader(m_assetDirectory.at("TornadoParticleSimFS.glsl"));
    
    const GLchar* feedbackVaryings[] = { "VsOut.position",
                                         "VsOut.parametricDist",
                                         "VsOut.rotationAngle" };
    glTransformFeedbackVaryings(m_shaderProgram_TFUpdate, 3, feedbackVaryings, GL_INTERLEAVED_ATTRIBS);
    
    m_shaderProgram_TFUpdate.link();
    
    
    //-- Query uniform locations:
    {
        m_uniformLocations.basisMatrix =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "basisMatrix");

        m_uniformLocations.derivMatrix =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "derivMatrix");
        
        m_uniformLocations.rotationRadius =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "rotationRadius");
        
        m_uniformLocations.rotationalVelocity =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "rotationalVelocity");
        
        m_uniformLocations.parametricVelocity =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "parametricVelocity");
        
        m_uniformLocations.deltaTime =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "deltaTime");
        
        m_uniformLocations.particleRandomness =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "particleRandomness");
        
        m_uniformLocations.numActiveParticles =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "numActiveParticles");
        
    }
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::initTransformFeedbackBuffers()
{
    // Allocate enough space for maxParticles.
    std::vector<ParticleData> particleData(m_maxParticles);
    
    // Randomnly seed particles throughout tornado.
    ParticleData initialData = { glm::vec3(0.0f), 0.0f, 0.0f };
    const float TWO_PI = 2.0f * M_PI;
    for(int i(0); i < m_maxParticles; ++i) {
        initialData.rotationAngle = rand0to1() * TWO_PI;
        initialData.parametricDist = rand0to1();
        particleData[i] = initialData;
    }
    
    GLsizeiptr numBytes = particleData.size() * sizeof(ParticleData);
    
    glGenBuffers(1, &m_TFBuffers.sourceVbo);
    glGenBuffers(1, &m_TFBuffers.destVbo);
    
    // Place particle data into source VBO.
    glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.sourceVbo);
    glBufferData(GL_ARRAY_BUFFER, numBytes, particleData.data(), GL_STREAM_COPY);
    
    // Allocate space for destination VBO
    glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.destVbo);
    glBufferData(GL_ARRAY_BUFFER, numBytes, nullptr, GL_STREAM_COPY);
    
    CHECK_GL_ERRORS;
}



//---------------------------------------------------------------------------------------
void ParticleSystemImpl::setupVertexAttribMappings()
{
    glGenVertexArrays(1, &m_vao_TFSource);
    glGenVertexArrays(1, &m_vao_TFDest);
    
    GLuint vao[] = {m_vao_TFSource, m_vao_TFDest};
    GLuint vertexBuffer[] = {m_TFBuffers.sourceVbo, m_TFBuffers.destVbo};
    
    for (int i(0); i < 2; ++i) {
        glBindVertexArray(vao[i]);
        
        // Enable vertex attribute slots
        glEnableVertexAttribArray(ATTRIBUTE_SLOT_0);
        glEnableVertexAttribArray(ATTRIBUTE_SLOT_1);
        CHECK_GL_ERRORS;
        
        // Set mapping of data from transform feedback buffer into
        // vertex attribute slots
        
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
        
        // Parametric Distance
        {
            GLsizei stride = sizeof(ParticleData);
            GLsizei offset = sizeof(glm::vec3);
            const GLint numComponents = 1;
            glVertexAttribPointer(ATTRIBUTE_SLOT_0, numComponents, GL_FLOAT, GL_FALSE, stride,
                                  reinterpret_cast<const GLvoid *>(offset));
            
            CHECK_GL_ERRORS;
        }
        
        // Rotation Angle
        {
            GLsizei stride = sizeof(ParticleData);
            GLsizei offset = sizeof(glm::vec3) + sizeof(float);
            const GLint numComponents = 1;
            glVertexAttribPointer(ATTRIBUTE_SLOT_1, numComponents, GL_FLOAT, GL_FALSE, stride,
                                  reinterpret_cast<const GLvoid *>(offset));
            
            CHECK_GL_ERRORS;
        }
        
    }
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::initTornadoCurve ()
{
    // Bezier curve control points
    m_tornadoCurve.p0 = glm::vec3(0.0f, -17.0f, -50.0f);
    m_tornadoCurve.p1 = glm::vec3(4.0f,  -9.0f,  -50.0f);
    m_tornadoCurve.p2 = glm::vec3(-3.0f, 3.0f, -10.0f);
    m_tornadoCurve.p3 = glm::vec3(0.0f, 9.0f,  -10.0f);

    ControlPointMotion & p0_motion = m_tornadoCurve.p0_motion;
    p0_motion.centerOfRotation = m_tornadoCurve.p0;
    p0_motion.radius = 1.0f;
    p0_motion.angle = 0.0f;
    p0_motion.rotationSpeed = 2.0f;
    
    ControlPointMotion & p3_motion = m_tornadoCurve.p3_motion;
    p3_motion.centerOfRotation = m_tornadoCurve.p3;
    p3_motion.radius = 2.0f;
    p3_motion.angle = 0.0f;
    p3_motion.rotationSpeed = 0.8f;
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::updateControlPointPosition (
    glm::vec3 & pointPosition,
    ControlPointMotion & pointMotion,
    float secondsSinceLastUpdate
) {
    float radius = pointMotion.radius * (1.0f + 2.0f * m_particleRandomness);
    float rotationSpeed = pointMotion.rotationSpeed * (2.0f * m_particleRandomness);
    float newAngle = pointMotion.angle + (rotationSpeed * secondsSinceLastUpdate);
    
    glm::vec3 x_dir(1.0f, 0.0f, 0.0f);
    glm::vec3 newPosition = radius * x_dir;
    newPosition = rotateY(newPosition, newAngle);
    newPosition += pointMotion.centerOfRotation;
    
    pointPosition = newPosition;
    pointMotion.angle = newAngle;
    
}

//---------------------------------------------------------------------------------------
void ParticleSystemImpl::updateTornadoCurveMotion (
    double secondsSinceLastUpdate
) {
    updateControlPointPosition(m_tornadoCurve.p0,
                               m_tornadoCurve.p0_motion,
                               secondsSinceLastUpdate);
    
    updateControlPointPosition(m_tornadoCurve.p3,
                               m_tornadoCurve.p3_motion,
                               secondsSinceLastUpdate);
    
    // Recompute Bezier curve matrices
    updateBezierMatricesFromControlPoint();
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::updateBezierMatricesFromControlPoint()
{
    glm::mat4 pMatrix = {
        glm::vec4(m_tornadoCurve.p0, 0.0f),
        glm::vec4(m_tornadoCurve.p1, 0.0f),
        glm::vec4(m_tornadoCurve.p2, 0.0f),
        glm::vec4(m_tornadoCurve.p3, 0.0f)
    };
    
    glm::mat4 coefficientMatrix = {
        { 1.0f,  0.0f,  0.0f,  0.0f},
        {-3.0f,  3.0f,  0.0f,  0.0f},
        { 3.0f, -6.0f,  3.0f,  0.0f},
        {-1.0f,  3.0f, -3.0f,  1.0f}
    };
    
    m_tornadoCurve.basisMatrix = pMatrix * coefficientMatrix;
    
    
    glm::mat4 derivCoefficientMatrix = {
        {-3.0f,  3.0f,  0.0f,  0.0f},
        { 6.0f, -12.0f, 6.0f,  0.0f},
        {-3.0f,  9.0f, -9.0f,  3.0f},
        { 0.0f,  0.0f,  0.0f,  0.0f},
    };
    
    m_tornadoCurve.derivMatrix = pMatrix * derivCoefficientMatrix;
    
}

//---------------------------------------------------------------------------------------
void ParticleSystemImpl::setStaticUniformData()
{
    m_shaderProgram_TFUpdate.enable();
    
    glUniform1f(m_uniformLocations.rotationRadius, 2.0f);
    
    glUniform1f(m_uniformLocations.rotationalVelocity, 10.0f);
    
    glUniform1f(m_uniformLocations.parametricVelocity, 0.2f);
    
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystem::update (
    double secondsSinceLastUpdate
) {
    impl->update(secondsSinceLastUpdate);
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::updateUniforms (
    double secondsSinceLastUpdate
) {
    glUniform1f(m_uniformLocations.deltaTime, secondsSinceLastUpdate);
    
    glUniform1f(m_uniformLocations.particleRandomness, m_particleRandomness);
    
    glUniform1f(m_uniformLocations.numActiveParticles, m_numActiveParticles);
    
    glUniformMatrix4fv(m_uniformLocations.basisMatrix, 1, GL_FALSE, &m_tornadoCurve.basisMatrix[0][0]);
    
    glUniformMatrix4fv(m_uniformLocations.derivMatrix, 1, GL_FALSE, &m_tornadoCurve.derivMatrix[0][0]);
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
void ParticleSystemImpl::update (
    double secondsSinceLastUpdate
) {
    updateTornadoCurveMotion(secondsSinceLastUpdate);
    
    m_shaderProgram_TFUpdate.enable();
    updateUniforms(secondsSinceLastUpdate);
    
    glBindVertexArray(m_vao_TFSource);
    
    // Prevent rasterization
    glEnable(GL_RASTERIZER_DISCARD);
    
    // Write transform feedback output to destination vbo.
    GLuint bindingIndex(0);
    glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, bindingIndex, m_TFBuffers.destVbo);
    
    glBeginTransformFeedback(GL_POINTS);
        glDrawArrays(GL_POINTS, 0, m_numActiveParticles);
    glEndTransformFeedback();
    
    
    // Swap source/destination transform feedback buffers
    std::swap(m_vao_TFSource, m_vao_TFDest);
    std::swap(m_TFBuffers.sourceVbo, m_TFBuffers.destVbo);
    
    glDisable(GL_RASTERIZER_DISCARD);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::setNumActiveParticles (
    uint numActiveParticles
) {
    // Prevent setting numActiveParticles to greater than maxParticles.
    m_numActiveParticles = std::min(numActiveParticles, m_maxParticles);
}


//---------------------------------------------------------------------------------------
void ParticleSystem::setNumActiveParticles (
    uint numActiveParticles
) {
    impl->setNumActiveParticles(numActiveParticles);
}


//---------------------------------------------------------------------------------------
uint ParticleSystem::numActiveParticles() const {
    return impl->m_numActiveParticles;
}


//---------------------------------------------------------------------------------------
GLuint ParticleSystem::particlePositionsVbo () const
{
    // After calling ParticleSystem::update(), the transform feedback destination buffer
    // is swapped with the transform feedback source buffer.
    return impl->m_TFBuffers.sourceVbo;
}


//---------------------------------------------------------------------------------------
VertexAttributeDescriptor ParticleSystem::getVertexDescriptorForParticlePositions() const
{
    return impl->getVertexDescriptorForParticlePositions();
}


//---------------------------------------------------------------------------------------
VertexAttributeDescriptor ParticleSystemImpl::getVertexDescriptorForParticlePositions() const
{
    VertexAttributeDescriptor descriptor;
    
    descriptor.numComponents = sizeof(ParticleData::position) / sizeof(float);
    descriptor.type = GL_FLOAT;
    descriptor.offset = 0;
    descriptor.stride = sizeof(ParticleData);
    
    return descriptor;
}


//---------------------------------------------------------------------------------------
void ParticleSystem::setParticleRandomness (
    float x
) {
    impl->m_particleRandomness = x;
}


//---------------------------------------------------------------------------------------
glm::vec3 ParticleSystem::getCenterOfTornado() const
{
    // Return center between Bezier control points p0 and p3.
    
    glm::vec3 p0 = impl->m_tornadoCurve.p0;
    glm::vec3 p3 = impl->m_tornadoCurve.p3;
    
    return p0 + ((p3 - p0) * 0.5f);
}
