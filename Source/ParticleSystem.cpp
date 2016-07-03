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


struct ParticlePosition {
    float positon[3];
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
    
    GLuint m_transformFeedbackObj_TFSource;
    GLuint m_transformFeedbackObj_TFDest;
    
    
    
    ParticleSystemImpl (
        const AssetDirectory & assetDirectory
    );
    
    void loadShaders();
    
    void loadTransformFeedbackBuffers();
    
    void setupVertexAttribMappings();
    
    void setupTransformFeedbackObjects();
    
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
    
    setupTransformFeedbackObjects();
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
    
    
    //-- Unbind target, and check for errors
    glBindBuffer(GL_ARRAY_BUFFER, 0);
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
void ParticleSystemImpl::setupTransformFeedbackObjects()
{
    // Set Transform Feedback Object binding for source buffer
    {
        glGenTransformFeedbacks(1, &m_transformFeedbackObj_TFSource);
        glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, m_transformFeedbackObj_TFSource);
        const GLuint bindingIndex = 0;
        glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, bindingIndex, m_TFBuffers.sourceVbo);
        CHECK_GL_ERRORS;
    }
    
    // Set Transform Feedback Object binding for destination buffer
    {
        glGenTransformFeedbacks(1, &m_transformFeedbackObj_TFDest);
        glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, m_transformFeedbackObj_TFDest);
        const GLuint bindingIndex = 0;
        glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, bindingIndex, m_TFBuffers.destVbo);
        CHECK_GL_ERRORS;
    }
}

//---------------------------------------------------------------------------------------
void ParticleSystem::update (
    double secondsSinceLastUpdate
) {
    impl->update(secondsSinceLastUpdate);
}

///////////////////////////////////
// TODO Dustin - Remove this:
#include <iostream>
using namespace std;
///////////////////////////////////

//---------------------------------------------------------------------------------------
void ParticleSystemImpl::update (
    double secondsSinceLastUpdate
) {
    
    static int count = 0;
    static GLuint destVbo = 0;
    static GLuint vao_source = 0;
    vao_source = (count == 0) ? m_vao_TFSource : m_vao_TFDest;
    destVbo = (count == 0) ? m_TFBuffers.destVbo : m_TFBuffers.sourceVbo;
    
    cout << "Transform feedback Start" << endl;
    
    
    m_shaderProgram_TFUpdate.enable();
    glBindVertexArray(vao_source);
    
    glEnable(GL_RASTERIZER_DISCARD);
    
    // Write transform feedback output to destination vbo.
    glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, destVbo);
    
    glBeginTransformFeedback(GL_POINTS);
        glDrawArrays(GL_POINTS, 0, m_numParticles);
    glEndTransformFeedback();
    
    cout << "Transform feedback end" << endl;
    
    
    count = (count + 1) % 2;
    //-- Restore defaults:
    glBindTransformFeedback(GL_TRANSFORM_FEEDBACK, 0);
    glDisable(GL_RASTERIZER_DISCARD);
    glBindVertexArray(0);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
void ParticleSystem::setNumParticles (
    uint numParticles
) {
    impl->m_numParticles = numParticles;
}


//---------------------------------------------------------------------------------------
void ParticleSystem::particlePositions (
    GLuint & vbo
) const {
    vbo = impl->m_TFBuffers.destVbo;
}


//---------------------------------------------------------------------------------------
// Retrieve vertex buffer object holding particle positions
void ParticleSystem::particlePositionElementSize (
    GLsizei & size
) const {
    size = sizeof(ParticlePosition);
}