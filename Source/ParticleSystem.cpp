//
//  ParticleSystem.cpp
//

#import "ParticleSystem.hpp"

#import <vector>
using std::vector;

#import <glm/glm.hpp>
using glm::vec3;

#import "ShaderProgram.hpp"
#import "AssetDirectory.hpp"
#import "VertexAttributeDefines.h"


#define NUM_POSITION_COMPONENTS 3
struct ParticlePosition {
    float positon[NUM_POSITION_COMPONENTS];
};

struct ParticleRotation {
    glm::vec3 axisOfRotation;
    float rotionalVelocity;
};


class ParticleSystemImpl {
private:
    friend class ParticleSystem;
    
    
//-- Members:
    uint m_numParticles;
    
    const AssetDirectory & m_assetDirectory;
    
    ShaderProgram m_shaderProgram_TFUpdate;
    struct UniformLocations {
        GLint deltaTime;
        GLint centerOfRotation;
    };
    UniformLocations m_uniformLocations;
    
    
    // Transform Feedback source/destination buffers.
    struct TransformFeedbackBuffers {
        GLuint sourceVbo;
        GLuint destVbo;
    };
    TransformFeedbackBuffers m_TFBuffers;
    
    GLuint m_vao_TFSource;
    GLuint m_vao_TFDest;
    
    GLuint m_vbo_particleRotation;
    
    
    
    
//-- Methods:
    ParticleSystemImpl (
        const AssetDirectory & assetDirectory,
        uint numParticles
    );
    
    void loadShaders();
    
    void loadTransformFeedbackPositionBuffers();
    
    void loadParticleRotationBuffers();
    
    void setupVertexAttribMappings();
    
    void setStaticUniformData();
    
    void update (
        double secondsSinceLastUpdate
    );
    
    void updateUniforms (
        double secondsSinceLastUpdate
    );
    
}; // end class ParticleSystemImpl


//---------------------------------------------------------------------------------------
ParticleSystemImpl::ParticleSystemImpl (
    const AssetDirectory & assetDirectory,
    uint numParticles
)
    : m_assetDirectory(assetDirectory),
      m_numParticles(numParticles)
{
    loadShaders();
    
    loadTransformFeedbackPositionBuffers();
    
    loadParticleRotationBuffers();
    
    setupVertexAttribMappings();
    
    setStaticUniformData();
}

//---------------------------------------------------------------------------------------
ParticleSystem::ParticleSystem (
    const AssetDirectory & assetDirectory,
    uint numParticles
) {
    impl = new ParticleSystemImpl(assetDirectory, numParticles);
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
    m_shaderProgram_TFUpdate.attachVertexShader(m_assetDirectory.at("TFUpdate.glsl"));
    m_shaderProgram_TFUpdate.attachFragmentShader(m_assetDirectory.at("TFUpdateFrag.glsl"));
    
    const GLchar* feedbackVaryings[] = { "VsOut.position" };
    glTransformFeedbackVaryings(m_shaderProgram_TFUpdate, 1, feedbackVaryings, GL_INTERLEAVED_ATTRIBS);
    
    m_shaderProgram_TFUpdate.link();
    
    
    //-- Query uniform locations:
    {
        m_uniformLocations.deltaTime =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "deltaTime");
        
        m_uniformLocations.centerOfRotation =
            glGetUniformLocation(m_shaderProgram_TFUpdate, "centerOfRotation");
    }
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::loadTransformFeedbackPositionBuffers()
{
    glGenBuffers(1, &m_TFBuffers.sourceVbo);
    glGenBuffers(1, &m_TFBuffers.destVbo);
    
    std::vector<glm::vec3> positionData = {
        {0.0f, 0.0f, -5.0f}
    };
    GLsizeiptr numBytes = positionData.size() * sizeof(ParticlePosition);
    numBytes *= m_numParticles;
    
    
    // Place position data into source VBO.
    glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.sourceVbo);
    glBufferData(GL_ARRAY_BUFFER, numBytes, positionData.data(), GL_STREAM_COPY);
    
    // Allocate space for destination VBO
    glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.destVbo);
    glBufferData(GL_ARRAY_BUFFER, numBytes, nullptr, GL_STREAM_COPY);
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::loadParticleRotationBuffers()
{
    glGenBuffers(1, &m_vbo_particleRotation);
    
    std::vector<ParticleRotation> particleRotations;
    ParticleRotation data;
    data.axisOfRotation = glm::vec3(0.2f, 0.9f, 0.0f);
    data.rotionalVelocity = 2.0f;
    particleRotations.push_back(data);
    
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo_particleRotation);
    
    // Allocate space for each of m_numParticles.
    GLsizeiptr numBytes = particleRotations.size() * sizeof(ParticleRotation);
    numBytes *= m_numParticles;
    glBufferData(GL_ARRAY_BUFFER, numBytes, particleRotations.data(), GL_STATIC_DRAW);
    
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
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        glEnableVertexAttribArray(ATTRIBUTE_SLOT_1);
        glEnableVertexAttribArray(ATTRIBUTE_SLOT_2);
        CHECK_GL_ERRORS;
        
        // Set mapping of data from transform feedback buffer into
        // vertex attribute slots
        
        // Position data
        {
            glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer[i]);
            glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, nullptr);
        }
        CHECK_GL_ERRORS;
        
        // Axis of Rotation data
        {
            glBindBuffer(GL_ARRAY_BUFFER, m_vbo_particleRotation);
            GLsizei stride = sizeof(ParticleRotation);
            GLsizei offset = 0;
            GLboolean normalizeYes(GL_TRUE);
            glVertexAttribPointer(ATTRIBUTE_SLOT_1, 3, GL_FLOAT, normalizeYes, stride,
                                  reinterpret_cast<const GLvoid *>(offset));
        }
        CHECK_GL_ERRORS;
        
        // Rotation velocity data
        {
            glBindBuffer(GL_ARRAY_BUFFER, m_vbo_particleRotation);
            GLsizei stride = sizeof(ParticleRotation);
            GLsizei offset = sizeof(ParticleRotation::axisOfRotation);
            glVertexAttribPointer(ATTRIBUTE_SLOT_2, 1, GL_FLOAT, GL_FALSE, stride,
                                  reinterpret_cast<const GLvoid *>(offset));
        }
        CHECK_GL_ERRORS;
    }
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::setStaticUniformData()
{
    const glm::vec3 centerOfRotations{0.0f, 0.0f, -6.0f};
    
    m_shaderProgram_TFUpdate.enable();
    glUniform3fv(m_uniformLocations.centerOfRotation, 1, &centerOfRotations[0]);
    
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
}

//---------------------------------------------------------------------------------------
void ParticleSystemImpl::update (
    double secondsSinceLastUpdate
) {
    m_shaderProgram_TFUpdate.enable();
    updateUniforms(secondsSinceLastUpdate);
    
    glBindVertexArray(m_vao_TFSource);
    
    // Prevent rasterization
    glEnable(GL_RASTERIZER_DISCARD);
    
    // Write transform feedback output to destination vbo.
    GLuint bindingIndex(0);
    glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, bindingIndex, m_TFBuffers.destVbo);
    
    glBeginTransformFeedback(GL_POINTS);
        glDrawArrays(GL_POINTS, 0, m_numParticles);
    glEndTransformFeedback();
    
    
    // Swap source/destination transform feedback buffers
    std::swap(m_vao_TFSource, m_vao_TFDest);
    std::swap(m_TFBuffers.sourceVbo, m_TFBuffers.destVbo);
    
    glDisable(GL_RASTERIZER_DISCARD);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystem::setNumParticles (
    uint numParticles
) {
    impl->m_numParticles = numParticles;
}

//---------------------------------------------------------------------------------------
uint ParticleSystem::numParticles() const {
    return impl->m_numParticles;
}


//---------------------------------------------------------------------------------------
GLuint ParticleSystem::particlePositionsVbo () const
{
    // After calling ParticleSystem::update(), the transform feedback destination buffer
    // is swapped with the transform feedback source buffer.
    return impl->m_TFBuffers.sourceVbo;
}


//---------------------------------------------------------------------------------------
GLsizei ParticleSystem::particlePositionElementSizeInBytes () const
{
    return sizeof(ParticlePosition);
}


//---------------------------------------------------------------------------------------
GLsizei ParticleSystem::numComponentsPerParticlePosition() const
{
    return NUM_POSITION_COMPONENTS;
}