//
//  ParticleSystem.hpp
//

#include "NumericTypes.h"
#include "AssetDirectory.hpp"


// Forward declaration
class ParticleSystemImpl;


class ParticleSystem {
public:
    ParticleSystem (
        const AssetDirectory & assetDirectory,
        uint numActiveParticles,
        uint maxParticles
    );
    
    ~ParticleSystem();
    
    
    // Requires numActiveParticles <= maxParticles.
    void setNumActiveParticles (
        uint numActiveParticles
    );
    
    // Query number of active particles.
    uint numActiveParticles() const;
    
    // Retrieve vertex buffer object for particle position data
    GLuint particlePositionsVbo () const;
    
    // Retrieve size of each particle position in bytes.
    GLsizei particlePositionElementSizeInBytes () const;
    
    // Retrieve number components per particle position.
    GLsizei numComponentsPerParticlePosition() const;
    
    
    // Advance particle system by the given time step.
    void update (
        double secondsSinceLastUpdate
    );
    
    
private:
    ParticleSystemImpl * impl;

};
