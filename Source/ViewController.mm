//
//  ViewController.m
//

#import "ViewController.h"
#import <glm/glm.hpp>

static const GLuint VertexAttrib_Position = 0;
static const GLuint VertexAttrib_Normal = 0;


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
    
    // Validate program
    [self validateProgram:_shaderProgram];
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindVertexArray(0);
    glUseProgram(0);
}

//---------------------------------------------------------------------------------------
- (BOOL)loadShaders
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
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
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
    if (![self linkProgram:_shaderProgram]) {
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
        
        return NO;
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
    
    return YES;
}


//---------------------------------------------------------------------------------------
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)shaderType file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
 
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(shaderType);
    CHECK_GL_ERRORS;
    
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
    CHECK_GL_ERRORS;
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


//---------------------------------------------------------------------------------------
- (BOOL)linkProgram:(GLuint)prog
{
    
    GLint status;
    glLinkProgram(prog);
    CHECK_GL_ERRORS;
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

//---------------------------------------------------------------------------------------
- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
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


