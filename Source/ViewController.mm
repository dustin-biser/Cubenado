//
//  ViewController.m
//

#import "ViewController.h"

#import "CubenadoRenderer.h"



@interface ViewController ()

@property (strong, nonatomic) EAGLContext * eaglContext;

- (void) setupSliderForNumCubes;

- (void) setupSliderForCubeRandomness;

- (void)sliderActionNumCubes:(id)sender forEvent:(UIEvent*)event;

@end


@implementation ViewController {
@private
    GLKView * _glkView;
    
    // Slider UI Controls
    UISlider * _slider_numCubes;
    UISlider * _slider_cubeRandomness;
    
    CubenadoRenderer * _cubenadoRenderer;
}


//---------------------------------------------------------------------------------------
- (void) viewDidLoad
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
    
    
    [self setupSliderForNumCubes];
    
    [self setupSliderForCubeRandomness];
}


//---------------------------------------------------------------------------------------
- (void) setupSliderForNumCubes
{
    CGRect frame = self.view.frame;
    _slider_numCubes = [[UISlider alloc] initWithFrame:frame];
    [self.view addSubview:_slider_numCubes];
    
    [_slider_numCubes addTarget:self
                         action:@selector(sliderActionNumCubes:forEvent:)
               forControlEvents:UIControlEventValueChanged];
    
    [_slider_numCubes setBackgroundColor:[UIColor clearColor]];
    _slider_numCubes.minimumValue = 0.0;
    _slider_numCubes.maximumValue = 1.0;
    _slider_numCubes.continuous = YES;
    _slider_numCubes.value = 0.5;
    
    _slider_numCubes.translatesAutoresizingMaskIntoConstraints = NO;
    
    auto viewMargins = self.view.layoutMarginsGuide;
    
    // Pin the leading edge of slider to viewMargin's leading edge
    [_slider_numCubes.leadingAnchor constraintEqualToAnchor:viewMargins.leadingAnchor].active = YES;
    
    // Pin the trailing edge of slider to viewMargin's trailing edge
    [_slider_numCubes.trailingAnchor constraintEqualToAnchor:viewMargins.trailingAnchor].active = YES;
    
    // Offset slider's bottom anchor by 15% from parent view's bottom anchor.
    CGFloat frameHeight = self.view.frame.size.height;
    CGFloat constantValue = -(frameHeight * 0.15f);
    [_slider_numCubes.bottomAnchor constraintEqualToAnchor:viewMargins.bottomAnchor
                                                  constant:constantValue].active = YES;
}


//---------------------------------------------------------------------------------------
- (void) setupSliderForCubeRandomness
{
    CGRect frame = self.view.frame;
    _slider_cubeRandomness = [[UISlider alloc] initWithFrame:frame];
    [self.view addSubview:_slider_cubeRandomness];
    
    [_slider_cubeRandomness addTarget:self
                         action:@selector(sliderActionCubeRandomness:forEvent:)
               forControlEvents:UIControlEventValueChanged];
    
    [_slider_cubeRandomness setBackgroundColor:[UIColor clearColor]];
    _slider_cubeRandomness.minimumValue = 0.0;
    _slider_cubeRandomness.maximumValue = 1.0;
    _slider_cubeRandomness.continuous = YES;
    _slider_cubeRandomness.value = 0.0;
    
    _slider_cubeRandomness.translatesAutoresizingMaskIntoConstraints = NO;
    
    auto viewMargins = self.view.layoutMarginsGuide;
    
    // Pin the leading edge of slider to viewMargin's leading edge
    {
        auto anchor = viewMargins.leadingAnchor;
        [_slider_cubeRandomness.leadingAnchor constraintEqualToAnchor:anchor].active = YES;
    }
    
    // Pin the trailing edge of slider to viewMargin's trailing edge
    {
        auto anchor = viewMargins.trailingAnchor;
        [_slider_cubeRandomness.trailingAnchor constraintEqualToAnchor:anchor].active = YES;
    }
    
    // Offset slider's bottom anchor by 5% from parent view's bottom anchor.
    {
        CGFloat frameHeight = self.view.frame.size.height;
        CGFloat constantValue = -(frameHeight * 0.05f);
        auto anchor = viewMargins.bottomAnchor;
        [_slider_cubeRandomness.bottomAnchor constraintEqualToAnchor:anchor
                                                            constant:constantValue].active = YES;
    }
}


//---------------------------------------------------------------------------------------
- (void)sliderActionNumCubes:(id)sender forEvent:(UIEvent*)event
{
    if ([sender isMemberOfClass:[UISlider class]])  {
        NSLog(@"Slider-NumCubes: %f", _slider_numCubes.value);
    }
}


//---------------------------------------------------------------------------------------
- (void)sliderActionCubeRandomness:(id)sender forEvent:(UIEvent*)event
{
    if ([sender isMemberOfClass:[UISlider class]])  {
        NSLog(@"Slider-CubeRandomness: %f", _slider_cubeRandomness.value);
    }
}

//---------------------------------------------------------------------------------------
// GLKViewController update method
- (void) update
{
    [_cubenadoRenderer update:[self timeSinceLastUpdate]];
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
