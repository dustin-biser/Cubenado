//
//  CubenadoRenderer.h
//

#import <Foundation/Foundation.h>

// Forward declaration
class ParticleSystem;


struct FramebufferSize {
    GLint width;
    GLint height;
};
typedef struct FramebufferSize FramebufferSize;


@interface CubenadoRenderer : NSObject

- (instancetype)initWithFramebufferSize: (FramebufferSize)framebufferSize
                               numCubes: (uint) numCubes
                               maxCubes: (uint) maxCubes
                         cubeRandomness: (float) cubeRandomness;

- (void) renderwithFramebufferSize: (FramebufferSize)framebufferSize;

- (void) update:(NSTimeInterval)timeSinceLastUpdate;

- (void) setNumCubes: (uint)numCubes;

- (void) setCubeRandomness: (float)cubeRandomness;

@end
