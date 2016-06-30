//
//  ViewController.m
//

#import "ViewController.h"


@interface ViewController () {
    
}
    
@property (strong, nonatomic) EAGLContext * eaglContext;

- (void) setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ViewController {
@private
    GLKView * _glkView;
    GLuint _shaderProgram;
    GLuint _vao;
    GLuint _vbo;
}


//---------------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a context
    self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.eaglContext) {
        NSLog(@"This device does not support OpenGL ES 3.0");
    }
    
    // Create a GLKit View
    self.view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _glkView = (GLKView *)self.view;
    _glkView.context = self.eaglContext;
    
    // Configure renderbuffers created by the view
    _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    _glkView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    
    self.preferredFramesPerSecond = 60;
    
    
    [self setupGL];
}


//---------------------------------------------------------------------------------------
- (void) setupGL
{
    [EAGLContext setCurrentContext:self.eaglContext];
    
    glClearColor(1, 1, 1, 1);
    
    // Read vertex shader source
    NSString * vertexShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
    const char * vertexShaderSourceCString = [vertexShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Create and compile vertex shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSourceCString, NULL);
    glCompileShader(vertexShader);
    
    // Read fragment shader source
    NSString * fragmentShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
    const char * fragmentShaderSourceCString = [fragmentShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Create and compile fragment shader
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSourceCString, NULL);
    glCompileShader(fragmentShader);
    
    // Create and link program
    _shaderProgram = glCreateProgram();
    glAttachShader(_shaderProgram, vertexShader);
    glAttachShader(_shaderProgram, fragmentShader);
    glLinkProgram(_shaderProgram);
    
    
    CGSize size = _glkView.frame.size;
    GLfloat aspect = static_cast<GLfloat>(size.width) / size.height;
    
    // Define geometry
    GLfloat square[] = {
        -0.5f, -0.5f*aspect,
        0.5f, -0.5f*aspect,
        -0.5f, 0.5f*aspect,
        0.5f, 0.5f*aspect
    };
    
    glGenBuffers(1, &_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    size_t numBytes = sizeof(square);
    glBufferData(GL_ARRAY_BUFFER, numBytes, square, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
    
    
    const char * aPositionCString = [@"a_position" cStringUsingEncoding:NSUTF8StringEncoding];
    GLuint aPosition = glGetAttribLocation(_shaderProgram, aPositionCString);
    glEnableVertexAttribArray(aPosition);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glVertexAttribPointer(aPosition, 2, GL_FLOAT, GL_FALSE, 0, nullptr);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindVertexArray(0);
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void) update
{
    // Update per frame constants here.
}


//---------------------------------------------------------------------------------------
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    GLint width = static_cast<GLint>(_glkView.drawableWidth);
    GLint height = static_cast<GLint>(_glkView.drawableHeight);
    glViewport(0, 0, width, height);
    
    // Clear the framebuffer
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_shaderProgram);
    glBindVertexArray(_vao);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindVertexArray(0);
    glUseProgram(0);
}

//---------------------------------------------------------------------------------------
- (void)tearDownGL
{
    // TODO - Implement this.
}

//---------------------------------------------------------------------------------------
- (BOOL)loadShaders
{
    
    // TODO - Implement this.
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    
    // TODO - Implement this.
    
    return YES;
}


- (BOOL)linkProgram:(GLuint)prog
{
    
    // TODO - Implement this.
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    
    // TODO - Implement this.
    
    return YES;
}


@end // end ViewController


