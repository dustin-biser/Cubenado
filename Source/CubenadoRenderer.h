//
//  CubenadoRenderer.h
//

#import <Foundation/Foundation.h>

struct FramebufferSize {
    GLint width;
    GLint height;
};
typedef struct FramebufferSize FramebufferSize;


@interface CubenadoRenderer : NSObject

- (instancetype)initWithFramebufferSize:(FramebufferSize)framebufferSize;

- (void) render:(FramebufferSize)framebufferSize;

- (void) update:(NSInteger)timeSinceLastUpdate;

@end
