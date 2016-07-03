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



class ParticleSystemImpl {
private:
    friend class ParticleSystem;
    
    
    uint m_numParticles;
    
    const AssetDirectory & m_assetDirectory;
    
    ShaderProgram m_shaderProgram_TFUpdate;
    
    // Transform Feedback source/destination buffers.
    struct TransformFeedbackBuffers {
        GLuint sourceVbo;
        GLuint destVbo;
    };
    TransformFeedbackBuffers m_TFBuffers;
    
    GLuint m_vao_TFSource;
    GLuint m_vao_TFDest;
    
    
    ParticleSystemImpl (
        const AssetDirectory & assetDirectory
    );
    
    void loadShaders();
    
    void loadTransformFeedbackBuffers();
    
    void setupVertexAttribMappings();
    
    void update (
        double secondsSinceLastUpdate
    );
    
}; // end class ParticleSystemImpl


//---------------------------------------------------------------------------------------
ParticleSystemImpl::ParticleSystemImpl (
    const AssetDirectory & assetDirectory
)
    : m_assetDirectory(assetDirectory),
      m_numParticles(0)

{
    loadShaders();
    
    loadTransformFeedbackBuffers();
    
    setupVertexAttribMappings();
}

//---------------------------------------------------------------------------------------
ParticleSystem::ParticleSystem (
    const AssetDirectory & assetDirectory
) {
    impl = new ParticleSystemImpl(assetDirectory);
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
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::loadTransformFeedbackBuffers()
{
    glGenBuffers(1, &m_TFBuffers.sourceVbo);
    glGenBuffers(1, &m_TFBuffers.destVbo);
    
    std::vector<glm::vec3> positionData = {
        {0.0f, 0.0f, 0.0f}
    };
    size_t numBytes = positionData.size() * sizeof(ParticlePosition);
    
    
    // Place position data into source VBO.
    glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.sourceVbo);
    glBufferData(GL_ARRAY_BUFFER, numBytes, positionData.data(), GL_STREAM_COPY);
    
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
    
    // Set mapping of data from transform feedback source buffer into
    // vertex attribute slots
    {
        glBindVertexArray(m_vao_TFSource);
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        
        glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.sourceVbo);
        glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, nullptr);
    }
    
    // Set mapping of data from transform feedback destination buffer into
    // vertex attribute slots
    {
        glBindVertexArray(m_vao_TFDest);
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        
        glBindBuffer(GL_ARRAY_BUFFER, m_TFBuffers.destVbo);
        glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, 0, nullptr);
    }
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
void ParticleSystem::update (
    double secondsSinceLastUpdate
) {
    impl->update(secondsSinceLastUpdate);
}


//---------------------------------------------------------------------------------------
void ParticleSystemImpl::update (
    double secondsSinceLastUpdate
) {
    m_shaderProgram_TFUpdate.enable();
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
    return impl->m_TFBuffers.destVbo;
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