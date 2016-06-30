//
//  ViewController.m
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
@private
    GLKView * _glkView;
    GLuint _shaderProgram;
    GLuint _vao;
    GLuint _vbo;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a context
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!context) {
        NSLog(@"This device does not support OpenGL ES 3.0");
    }
    [EAGLContext setCurrentContext:context];
    
    // Create a GLKit View
    self.view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _glkView = (GLKView *)self.view;
    _glkView.context = context;
    
    // Configure renderbuffers created by the view
    _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    _glkView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    
    self.preferredFramesPerSecond = 60;
    
    
    
    // Set the viewport
    GLsizei width = 2*_glkView.frame.size.width;
    GLsizei height = 2*_glkView.frame.size.height;
    glViewport(0, 0, width, height);
    
    // Clear
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
    
    
    GLfloat aspect = static_cast<GLfloat>(width) / height;
    
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
    
    
    glUseProgram(_shaderProgram);
        const char * aPositionCString = [@"a_position" cStringUsingEncoding:NSUTF8StringEncoding];
        GLuint aPosition = glGetAttribLocation(_shaderProgram, aPositionCString);
        glEnableVertexAttribArray(aPosition);
    glUseProgram(0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glVertexAttribPointer(aPosition, 2, GL_FLOAT, GL_FALSE, 0, nullptr);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindVertexArray(0);
}



- (void) update
{
    // Update per frame constants here.
}



- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear the framebuffer
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_shaderProgram);
    glBindVertexArray(_vao);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindVertexArray(0);
    glUseProgram(0);
}


@end // end ViewController


