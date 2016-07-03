//
//  ViewController.m
//

#import "ViewController.h"

#import "CubenadoRenderer.h"



@interface ViewController ()

@property (strong, nonatomic) EAGLContext * eaglContext;

@end


@implementation ViewController {
@private
    GLKView * _glkView;
    CubenadoRenderer * _cubenadoRenderer;
}


//---------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a the GL context
    self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.eaglContext) {
        NSLog(@"This device does not support OpenGL ES 3.0");
    }
    // Set as the current GL context.
    [EAGLContext setCurrentContext:self.eaglContext];
    
    // Create a GLKit View
    self.view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _glkView = (GLKView *)self.view;
    _glkView.context = self.eaglContext;
    
    // Configure renderbuffer formats created by the GLKView
    {
        // sRGB format for gamma correction
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatSRGBA8888;
        
        // Depth stencil formats
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        _glkView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    }
    
    
    self.preferredFramesPerSecond = 60;
    
    
    // Calculate screen dimensions now, and use as FramebufferSize.
    // The GLKView's drawabale surface is not gauranteed to be loaded until just
    // before [GLKViewController glkView:drawInRect:] is called.
    FramebufferSize framebufferSize;
    CGSize frameSize = _glkView.frame.size;
    framebufferSize.width = static_cast<GLint>(frameSize.width);
    framebufferSize.height = static_cast<GLint>(frameSize.height);
    
    _cubenadoRenderer = [[CubenadoRenderer alloc] initWithFramebufferSize:framebufferSize];
}


//---------------------------------------------------------------------------------------
// GLKViewController update method
- (void) update
{
    [_cubenadoRenderer update];
}


//---------------------------------------------------------------------------------------
// GLKViewController glkView method
// View has requested a refresh, so draw next frame here
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    FramebufferSize framebufferSize;
    framebufferSize.width = static_cast<GLint>(_glkView.drawableWidth);
    framebufferSize.height = static_cast<GLint>(_glkView.drawableHeight);
    
    [_cubenadoRenderer render: framebufferSize];
}


//---------------------------------------------------------------------------------------
- (void)dealloc
{
    if ([EAGLContext currentContext] == self.eaglContext) {
        [EAGLContext setCurrentContext:nil];
    }
}

//---------------------------------------------------------------------------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        if ([EAGLContext currentContext] == self.eaglContext) {
            [EAGLContext setCurrentContext:nil];
        }
        self.eaglContext = nil;
    }
    
    // Dispose of any other memory resources here...
}


@end // @implementation ViewController
