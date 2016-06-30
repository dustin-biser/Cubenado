//
//  ViewController.m
//

#import "ViewController.h"

#import <vector>
using std::vector;

#import <glm/glm.hpp>

#import "GLUtils.h"

static const GLuint VertexAttrib_Position = 0;
static const GLuint VertexAttrib_Normal = 0;


struct Vertex {
    GLfloat position[4];
    GLfloat normal[4];
};


@interface ViewController () {
    
}
    
@property (strong, nonatomic) EAGLContext * eaglContext;

- (void) setupGL;

- (void)tearDownGL;

- (void)loadShaders;

- (void) loadVertexBuffers;

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
    
    // Create a the GL context
    self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!self.eaglContext) {
        NSLog(@"This device does not support OpenGL ES 3.0");
    }
    
    // Create a GLKit View
    self.view = [[GLKView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _glkView = (GLKView *)self.view;
    _glkView.context = self.eaglContext;
    
    // Configure renderbuffers created by the GLKView
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
    
    [self loadShaders];
    
    glClearColor(1, 1, 1, 1);
    
    
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
    
    
    glEnableVertexAttribArray(VertexAttrib_Position);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glVertexAttribPointer(VertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, nullptr);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindVertexArray(0);
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) loadVertexBuffers
{
    // Cube vertex data.
    std::vector<Vertex> vertexData = {
        // Positions             Normals
        // Bottom
        { -0.5f, -0.5f,  0.5f,   0.0f, -1.0f,  0.0f}, // 0
        {  0.5f, -0.5f,  0.5f,   0.0f, -1.0f,  0.0f}, // 1
        {  0.5f, -0.5f, -0.5f,   0.0f, -1.0f,  0.0f}, // 2
        { -0.5f, -0.5f, -0.5f,   0.0f, -1.0f,  0.0f}, // 3
        
        // Top
        { -0.5f,  0.5f,  0.5f,   0.0f,  1.0f,  0.0f}, // 4
        {  0.5f,  0.5f,  0.5f,   0.0f,  1.0f,  0.0f}, // 5
        {  0.5f,  0.5f, -0.5f,   0.0f,  1.0f,  0.0f}, // 6
        { -0.5f,  0.5f, -0.5f,   0.0f,  1.0f,  0.0f}, // 7
        
        // Left
        { -0.5f, -0.5f,  0.5f,  -1.0f,  0.0f,  0.0f}, // 8
        { -0.5f, -0.5f, -0.5f,  -1.0f,  0.0f,  0.0f}, // 9
        { -0.5f,  0.5f,  0.5f,  -1.0f,  0.0f,  0.0f}, // 10
        { -0.5f,  0.5f, -0.5f,  -1.0f,  0.0f,  0.0f}, // 11
        
        // Back
        { -0.5f, -0.5f, -0.5f,   0.0f,  0.0f, -1.0f}, // 12
        {  0.5f, -0.5f, -0.5f,   0.0f,  0.0f, -1.0f}, // 13
        {  0.5f,  0.5f, -0.5f,   0.0f,  0.0f, -1.0f}, // 14
        { -0.5f,  0.5f, -0.5f,   0.0f,  0.0f, -1.0f}, // 15
        
        // Right
        {  0.5f, -0.5f,  0.5f,   1.0f,  0.0f,  0.0f}, // 16
        {  0.5f, -0.5f, -0.5f,   1.0f,  0.0f,  0.0f}, // 17
        {  0.5f,  0.5f, -0.5f,   1.0f,  0.0f,  0.0f}, // 18
        {  0.5f,  0.5f,  0.5f,   1.0f,  0.0f,  0.0f}, // 19
        
        // Front
        { -0.5f, -0.5f,  0.5f,   0.0f,  0.0f,  1.0f}, // 20
        {  0.5f, -0.5f,  0.5f,   0.0f,  0.0f,  1.0f}, // 21
        {  0.5f,  0.5f,  0.5f,   0.0f,  0.0f,  1.0f}, // 22
        { -0.5f,  0.5f,  0.5f,   0.0f,  0.0f,  1.0f}, // 23
    };
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
    
    VALIDATE_GL_PROGRAM(_shaderProgram);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindVertexArray(0);
    glUseProgram(0);
}


//---------------------------------------------------------------------------------------
- (void)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _shaderProgram = glCreateProgram();
    if(_shaderProgram == 0) {
        NSLog(@"Failed to create shader program.");
        throw;
    }
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"glsl"];
    if (![GLUtils compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        throw;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"];
    if (![GLUtils compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        throw;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_shaderProgram, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_shaderProgram, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_shaderProgram, VertexAttrib_Position, "position");
    glBindAttribLocation(_shaderProgram, VertexAttrib_Normal, "normal");
    CHECK_GL_ERRORS;
    
    // Link program.
    if (![GLUtils linkProgram:_shaderProgram]) {
        NSLog(@"Failed to link program: %d", _shaderProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_shaderProgram) {
            glDeleteProgram(_shaderProgram);
            _shaderProgram = 0;
        }
        
        throw;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_shaderProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_shaderProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void)dealloc
{
    [self tearDownGL];
    
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
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.eaglContext) {
            [EAGLContext setCurrentContext:nil];
        }
        self.eaglContext = nil;
    }
    
    // Dispose of any other memory resources here...
}


//---------------------------------------------------------------------------------------
- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.eaglContext];
    
    glDeleteBuffers(1, &_vbo);
    glDeleteVertexArrays(1, &_vao);
    
    if (_shaderProgram) {
        glDeleteProgram(_shaderProgram);
        _shaderProgram = 0;
    }
}



@end // end ViewController


