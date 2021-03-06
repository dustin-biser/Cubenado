//
//  ParticleSystem.hpp
//

#include "NumericTypes.h"
#include "AssetDirectory.hpp"
#import <OpenGLES/ES3/gl.h>

#import <glm/glm.hpp>

// Forward declaration
class ParticleSystemImpl;


struct VertexAttributeDescriptor
{
    GLint numComponents;
    GLenum type;
    GLsizei stride;
    const GLvoid * offset;
};


class ParticleSystem {
public:
    ParticleSystem (
        const AssetDirectory & assetDirectory,
        uint numActiveParticles,
        uint maxParticles,
        float particleRandomness
    );
    
    ~ParticleSystem();
    
    
    // Requires numActiveParticles <= maxParticles.
    void setNumActiveParticles (
        uint numActiveParticles
    );
    
    // Query number of active particles.
    uint numActiveParticles() const;
    
    // Return vertex attribute layout for interleaved particle position data.
    VertexAttributeDescriptor getVertexDescriptorForParticlePositions() const;
    
    // Returns Vertex Buffer object referencing particle position data.
    GLuint particlePositionsVbo () const;
    
    // Clamped value between [0,1] for degee of randomness of particle motion.
    void setParticleRandomness(float x);
    
    // Advance particle system by the given time step.
    void update (
        double secondsSinceLastUpdate
    );
    
    
    glm::vec3 getCenterOfTornado() const;
    
private:
    ParticleSystemImpl * impl;

};
