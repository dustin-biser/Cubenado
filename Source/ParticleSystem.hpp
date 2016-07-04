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
        uint numParticles
    );
    
    ~ParticleSystem();
    
    
    void setNumParticles (
        uint numParticles
    );
    
    uint numParticles() const;
    
    // Retrieve vertex buffer object for particle position data
    GLuint particlePositionsVbo () const;
    
    // Retrieve size of each particle position in bytes.
    GLsizei particlePositionElementSizeInBytes () const;
    
    // Retrieve number components per particle position.
    GLsizei numComponentsPerParticlePosition() const;
    
    
    void update (
        double secondsSinceLastUpdate
    );
    
    
private:
    ParticleSystemImpl * impl;

};
