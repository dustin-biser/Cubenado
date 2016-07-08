//
//  CubenadoRenderer.h
//

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

// Forward declaration
@class GLKView;


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

- (void) renderWithGLKView: (GLKView *)glkView;

- (void) update:(NSTimeInterval)timeSinceLastUpdate;

- (void) setNumCubes: (uint)numCubes;

- (void) setCubeRandomness: (float)cubeRandomness;

@end
