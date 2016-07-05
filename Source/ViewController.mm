//
//  ViewController.m
//

#import "ViewController.h"

#import "CubenadoRenderer.h"


#define MIN_NUMBER_OF_CUBES 10
#define MAX_NUMBER_OF_CUBES 10000


@interface ViewController ()

@property (strong, nonatomic) EAGLContext * eaglContext;

- (void) setupSliderForNumCubes;

- (void) setupSliderForCubeRandomness;

- (void) sliderActionNumCubes:(id)sender forEvent:(UIEvent*)event;

- (void) sliderActionCubeRandomness:(id)sender forEvent:(UIEvent*)event;

- (void) layoutUIControls;


- (NSString *) constructLabelTextForNumCubesLabel;

- (NSString *) constructLabelTextForCubeRandomnessLabel;

@end


@implementation ViewController {
@private
    GLKView * _glkView;
    
    // Slider UI Controls
    UISlider * _slider_numCubes;
    UISlider * _slider_cubeRandomness;
    UILabel * _label_forSliderNumCubes;
    UILabel * _label_forSliderCubeRandomness;
    
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
    [self layoutUIControls];
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
    _slider_numCubes.minimumValue = MIN_NUMBER_OF_CUBES;
    _slider_numCubes.maximumValue = MAX_NUMBER_OF_CUBES;
    _slider_numCubes.continuous = YES;
    _slider_numCubes.value = (MAX_NUMBER_OF_CUBES - MIN_NUMBER_OF_CUBES) * 0.2f;
    
    //-- Label for slider:
    {
        _label_forSliderNumCubes = [[UILabel alloc] initWithFrame:frame];
        [self.view addSubview:_label_forSliderNumCubes];
        
        _label_forSliderNumCubes.text = [self constructLabelTextForNumCubesLabel];
        
        _label_forSliderNumCubes.textAlignment = NSTextAlignmentLeft;
    }
}


//---------------------------------------------------------------------------------------
- (NSString *) constructLabelTextForNumCubesLabel
{
    uint numCubes = static_cast<uint>(_slider_numCubes.value);
    return [NSString stringWithFormat:@"Number of Cubes: %d", numCubes];
}


//---------------------------------------------------------------------------------------
- (NSString *) constructLabelTextForCubeRandomnessLabel
{
    float value = _slider_cubeRandomness.value * 100.0f;
    return [NSString stringWithFormat:@"Cube Randomness: %.1f%%", value];
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
    _slider_cubeRandomness.value = 0.2f;
    
    //-- Label for slider:
    {
        _label_forSliderCubeRandomness = [[UILabel alloc] initWithFrame:frame];
        [self.view addSubview:_label_forSliderCubeRandomness];
        
        _label_forSliderCubeRandomness.text =
            [self constructLabelTextForCubeRandomnessLabel];
        
        _label_forSliderCubeRandomness.textAlignment = NSTextAlignmentLeft;
    }
}


//---------------------------------------------------------------------------------------
- (void) layoutUIControls
{
    
    // Disable autolayout contrains
    _slider_numCubes.translatesAutoresizingMaskIntoConstraints = NO;
    _slider_cubeRandomness.translatesAutoresizingMaskIntoConstraints = NO;
    _label_forSliderNumCubes.translatesAutoresizingMaskIntoConstraints = NO;
    _label_forSliderCubeRandomness.translatesAutoresizingMaskIntoConstraints = NO;
    
    auto viewMargins = self.view.layoutMarginsGuide;
    CGSize viewFrameSize = self.view.frame.size;
    
    UISlider * slider;
    UILabel * label;
    
    const CGFloat verticalPadding = -viewFrameSize.height * 0.01f;
    const CGFloat horizontalLeftPadding = viewFrameSize.width * 0.01f;
    const CGFloat horizontalRightPadding = -horizontalLeftPadding;
    
    //-- Layout UISlider for cube randomness:
    slider = _slider_cubeRandomness;
    [slider.bottomAnchor constraintEqualToAnchor:viewMargins.bottomAnchor
                                        constant:verticalPadding].active = YES;
    [slider.leadingAnchor constraintEqualToAnchor:viewMargins.leadingAnchor
                                         constant:horizontalLeftPadding].active = YES;
    [slider.trailingAnchor constraintEqualToAnchor:viewMargins.trailingAnchor
                                           constant:horizontalRightPadding].active = YES;
    
    //-- Layout UILable for cube randomness:
    label = _label_forSliderCubeRandomness;
    [label.bottomAnchor constraintEqualToAnchor:_slider_cubeRandomness.topAnchor
                                       constant:0].active = YES;
    [label.leadingAnchor constraintEqualToAnchor:viewMargins.leadingAnchor
                                       constant:horizontalLeftPadding].active = YES;
    
    //-- Layout UISlider for num cubes:
    slider = _slider_numCubes;
    [slider.bottomAnchor constraintEqualToAnchor:_label_forSliderCubeRandomness.topAnchor
                                        constant:verticalPadding].active = YES;
    [slider.leadingAnchor constraintEqualToAnchor:viewMargins.leadingAnchor
                                         constant:horizontalLeftPadding].active = YES;
    [slider.trailingAnchor constraintEqualToAnchor:viewMargins.trailingAnchor
                                          constant:horizontalRightPadding].active = YES;
    
    //-- Layout UILabel for num cubes:
    label = _label_forSliderNumCubes;
    [label.bottomAnchor constraintEqualToAnchor:_slider_numCubes.topAnchor
                                       constant:0].active = YES;
    [label.leadingAnchor constraintEqualToAnchor:viewMargins.leadingAnchor
                                       constant:horizontalLeftPadding].active = YES;
    
}



//---------------------------------------------------------------------------------------
- (void)sliderActionNumCubes:(id)sender forEvent:(UIEvent*)event
{
    if ([sender isMemberOfClass:[UISlider class]])  {
        _label_forSliderNumCubes.text = [self constructLabelTextForNumCubesLabel];
    }
}


//---------------------------------------------------------------------------------------
- (void)sliderActionCubeRandomness:(id)sender forEvent:(UIEvent*)event
{
    if ([sender isMemberOfClass:[UISlider class]])  {
        _label_forSliderCubeRandomness.text = [self constructLabelTextForCubeRandomnessLabel];
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
