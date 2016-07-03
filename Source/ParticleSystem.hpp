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
        const AssetDirectory & assetDirectory
    );
    
    ~ParticleSystem();
    
    
    void setNumParticles (
        uint numParticles
    );
    
    // Retrieve vertex buffer object holding particle positions
    void particlePositions (
        GLuint & vbo
    ) const;
    
    // Retrieve vertex buffer object holding particle positions
    void particlePositionElementSize (
        GLsizei & size
    ) const;
    
    
    void update (
        double secondsSinceLastUpdate
    );
    
    
private:
    ParticleSystemImpl * impl;

};
