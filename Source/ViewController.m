//
//  ViewController.m
//

#import "ViewController.h"
#import "GLView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a context
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
    
    // Create a view
    GLView *glView = [[GLView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:glView];
    
    // Create a renderbuffer
    GLuint renderbuffer;
    glGenRenderbuffers(1, &renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)glView.layer];
    
    // Create a framebuffer
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    
    // Set the viewport
    glViewport(0, 0, glView.frame.size.width, glView.frame.size.height);
    
    // Clear
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);

    
    // Read vertex shader source
    NSString *vertexShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
    const char *vertexShaderSourceCString = [vertexShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Create and compile vertex shader
    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSourceCString, NULL);
    glCompileShader(vertexShader);
    
    // Read fragment shader source
    NSString *fragmentShaderSource = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
    const char *fragmentShaderSourceCString = [fragmentShaderSource cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Create and compile fragment shader
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSourceCString, NULL);
    glCompileShader(fragmentShader);
    
    // Create and link program
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);
    
    // Use program
    glUseProgram(program);

    
    // Define geometry
    GLfloat square[] = {
        -0.5, -0.5,
        0.5, -0.5,
        -0.5, 0.5,
        0.5, 0.5};
    
    //Send geometry to vertex shader
    const char *aPositionCString = [@"a_position" cStringUsingEncoding:NSUTF8StringEncoding];
    GLuint aPosition = glGetAttribLocation(program, aPositionCString);
    
    glVertexAttribPointer(aPosition, 2, GL_FLOAT, GL_FALSE, 0, square);
    glEnableVertexAttribArray(aPosition);
    
    // Draw
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // Present renderbuffer
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
