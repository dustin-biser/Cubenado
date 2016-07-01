//
//  ViewController.m
//

#import "ViewController.h"

#import <vector>
using std::vector;

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/matrix_transform.hpp>

#import "GLUtils.h"

static const GLuint VertexAttrib_Position = 0;
static const GLuint VertexAttrib_Normal = 1;


struct Transforms {
    glm::mat4 modelViewMatrix;
    glm::mat4 mvpMatrix;
    glm::mat4 normalMatrix;
};
static const GLuint UniformBindingIndex_Transforms = 0;

struct LightSource {
    glm::vec4 position;      // Light position in eye coordinate space.
    glm::vec4 rgbIntensity;  // Light intensity for each RGB component.
};
static const GLuint UniformBindingIndex_LightSource = 1;


struct Material {
    glm::vec4 Ka;        // Coefficients of ambient reflectivity for each RGB component.
    glm::vec4 Kd;        // Coefficients of diffuse reflectivity for each RGB component.
};
static const GLuint UniformBindingIndex_Matrial = 2;


// Align value to the next multiple of alignment.
template <typename T>
static T align(T value, T alignment)
{
    return ((value + (alignment - 1)) & ~(alignment - 1));
}


struct Vertex {
    GLfloat position[3];
    GLfloat normal[3];
};

typedef GLushort Index;





@interface ViewController () {
    
}
    
@property (strong, nonatomic) EAGLContext * eaglContext;

- (void) setupGL;

- (void) tearDownGL;

- (void) loadShaders;

- (void) loadVertexBuffers;

- (void) loadVertexArrays;

- (void) loadUniforms;

- (void) setUBOBindings;

@end

@implementation ViewController {
@private
    GLKView * _glkView;

    GLuint _shaderProgram;
    GLuint _vao;                // Vertex Array Object
    GLuint _vbo_cube;           // Vertex Buffer
    GLuint _indexBuffer_cube;   // Index Buffer
    GLsizei _numCubeIndices;
    
    
    GLsizei _framebufferWidth;
    GLsizei _framebufferHeight;
    
    
    // Uniform Buffer Data
    GLuint _ubo;
    GLuint _uboBufferSize;
    Transforms _sceneTransforms;
    GLint _uboOffset_Transforms;
    GLint _unifomBlockSize_Transforms;
    
    LightSource _lightSource;
    GLint _uboOffset_LightSource;
    GLint _uniformBlockSize_LightSource;
    
    Material _material;
    GLint _uboOffset_Material;
    GLint _uniformBlockSize_Material;
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
    
    // Configure renderbuffer formats created by the GLKView
    {
        // sRGB format for gamma correction
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatSRGBA8888;
        
        // Depth stencil formats
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        _glkView.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    }
    
    
    self.preferredFramesPerSecond = 60;
    
    
    [self setupGL];
}


//---------------------------------------------------------------------------------------
- (void) setupGL
{
    [EAGLContext setCurrentContext:self.eaglContext];
    
    [self loadShaders];

    [self loadVertexBuffers];

    [self loadVertexArrays];
    
    [self setUBOBindings];
    
    [self loadUniforms];
    

    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClearDepthf(1.0f);
    
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    glDepthFunc(GL_LEQUAL);
    glDepthRangef(0.0f, 1.0f);
    
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);
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

    // Load Vertex Data
    {
        glGenBuffers(1, &_vbo_cube);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_cube);
        size_t numBytes = vertexData.size() * sizeof(Vertex);
        glBufferData(GL_ARRAY_BUFFER, numBytes, vertexData.data(), GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        CHECK_GL_ERRORS;
    }


    std::vector<Index> indexData = {
            // Bottom
            3,1,0, 3,2,1,
            // Top
            7,4,5, 7,5,6,
            // Left
            8,10,9, 10,11,9,
            // Back
            12,15,13, 15,14,13,
            // Right
            16,17,19, 17,18,19,
            // Front
            20,21,23, 21,22,23
    };
    _numCubeIndices = static_cast<GLsizei>(indexData.size());

    // Load Index Data
    {
        glGenBuffers(1, &_indexBuffer_cube);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer_cube);
        size_t numBytes = indexData.size() * sizeof(Index);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numBytes, indexData.data(), GL_STATIC_DRAW);
        CHECK_GL_ERRORS;
    }
}

//---------------------------------------------------------------------------------------
- (void)loadVertexArrays
{
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer_cube);

    // Enable vertex attribute slots
    {
        glBindVertexArray(_vao);
        glEnableVertexAttribArray(VertexAttrib_Position);
        glEnableVertexAttribArray(VertexAttrib_Normal);
    }

    // Bind for use with glVertexAttribPointer(...).
    glBindBuffer(GL_ARRAY_BUFFER, _vbo_cube);
    
    // Position data mapping from VBO to vertex attribute slot
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset(0);
        glVertexAttribPointer(VertexAttrib_Position, 3, GL_FLOAT, GL_FALSE, stride,
            reinterpret_cast<const GLvoid *>(startOffset));
    }
    
    // Normal data mapping from VBO to vertex attribute slot
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset = sizeof(Vertex::position);
        glVertexAttribPointer(VertexAttrib_Normal, 3, GL_FLOAT, GL_FALSE, stride,
            reinterpret_cast<const GLvoid *>(startOffset));
    }


    //-- Unbind, and restore defaults
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) loadUniforms
{
    float fovy = 45.0f;
    CGSize size = _glkView.bounds.size;
    float aspect = size.width / size.height;
    glm::mat4 projectionMatrix = glm::perspective(glm::radians(fovy), aspect, 0.1f, 100.0f);
    
    glm::mat4 viewMatrix = glm::lookAt (
        glm::vec3{0.0f, 0.0f, 0.0f},  // eye
        glm::vec3{0.0f, 0.0f, -1.0f}, // center
        glm::vec3{0.0f, 1.0f, 0.0f}   // up
    );
    
    float angle = M_PI * 0.25f;
    glm::mat4 rotMatrix = glm::rotate(glm::mat4(), angle, glm::vec3(1.0f, 1.0f, 1.0f));
    glm::mat4 transMatrix = glm::translate(glm::mat4(), glm::vec3(0.0f, 0.0f, -5.0f));
    glm::mat4 modelMatrix = transMatrix * rotMatrix;
    glm::mat4 modelViewMatrix = viewMatrix * modelMatrix;
    _sceneTransforms.modelViewMatrix = modelViewMatrix;
    _sceneTransforms.mvpMatrix = projectionMatrix * modelViewMatrix;
    
    // modelViewMatrix scale is uniform, so
    // inverse = transpose -> normalMatrix = modelViewMatrix
    _sceneTransforms.normalMatrix = glm::mat3(modelViewMatrix);
    
    
    // Convert lightSource position to EyeSpace.
    glm::vec4 lightPosition = glm::vec4(-2.0f, 5.0f, 5.0f, 1.0f);
    _lightSource.position = viewMatrix * lightPosition;
    _lightSource.rgbIntensity = glm::vec4(1.0f, 1.0f, 1.0f, 1.0f);
    
    
    _material.Ka = glm::vec4(1.0f);
    _material.Kd = glm::vec4(0.2f, 0.4f, 8.0f, 0.0f);
    
    //-- Copy uniform block data to uniform buffer
    {
        glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
        GLvoid * pUniformBuffer = glMapBufferRange(GL_UNIFORM_BUFFER, 0, _uboBufferSize,
                                                   GL_MAP_WRITE_BIT);
        // Copy Transform data to uniform buffer.
        memcpy((char *)pUniformBuffer + _uboOffset_Transforms,
               &_sceneTransforms, sizeof(_sceneTransforms));
        
        // Copy LightSource data to uniform buffer.
        memcpy((char *)pUniformBuffer + _uboOffset_LightSource,
               &_lightSource, sizeof(_lightSource));
        
        // Copy Material data to uniform buffer.
        memcpy((char *)pUniformBuffer + _uboOffset_Material,
               &_material, sizeof(_material));
        
        glUnmapBuffer(GL_UNIFORM_BUFFER);
        glBindBuffer(GL_UNIFORM_BUFFER, 0);
        CHECK_GL_ERRORS;
    }
}

//---------------------------------------------------------------------------------------
- (void) setUBOBindings
{
    // Query uniform block indices
    GLuint blockIndex0 = glGetUniformBlockIndex(_shaderProgram, "Transforms");
    GLuint blockIndex1 = glGetUniformBlockIndex(_shaderProgram, "LightSource");
    GLuint blockIndex2 = glGetUniformBlockIndex(_shaderProgram, "Material");
    
    // Query uniform block size
    glGetActiveUniformBlockiv(_shaderProgram, blockIndex0, GL_UNIFORM_BLOCK_DATA_SIZE,
            &_unifomBlockSize_Transforms);
    glGetActiveUniformBlockiv(_shaderProgram, blockIndex1, GL_UNIFORM_BLOCK_DATA_SIZE,
            &_uniformBlockSize_LightSource);
    glGetActiveUniformBlockiv(_shaderProgram, blockIndex2, GL_UNIFORM_BLOCK_DATA_SIZE,
            &_uniformBlockSize_Material);
    
    
    // Bind shader block index to uniform buffer binding index
    glUniformBlockBinding(_shaderProgram, blockIndex0, UniformBindingIndex_Transforms);
    glUniformBlockBinding(_shaderProgram, blockIndex1, UniformBindingIndex_LightSource);
    glUniformBlockBinding(_shaderProgram, blockIndex2, UniformBindingIndex_Matrial);
    
    GLint uboOffsetAlignment;
    glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &uboOffsetAlignment);
    
    // Create Uniform Buffer
    glGenBuffers(1, &_ubo);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
    _uboBufferSize =  align(_unifomBlockSize_Transforms, uboOffsetAlignment) +
                      align(_uniformBlockSize_LightSource, uboOffsetAlignment) +
                      _uniformBlockSize_Material;
    glBufferData(GL_UNIFORM_BUFFER, _uboBufferSize, nullptr, GL_DYNAMIC_DRAW);
    
    // Map range of uniform buffer to uniform buffer binding index
    GLint offSet = 0;
    _uboOffset_Transforms = offSet;
    glBindBufferRange(GL_UNIFORM_BUFFER, UniformBindingIndex_Transforms, _ubo,
                      _uboOffset_Transforms, _unifomBlockSize_Transforms);
    offSet += _unifomBlockSize_Transforms;
    offSet = align(offSet, uboOffsetAlignment);
    _uboOffset_LightSource = offSet;
    glBindBufferRange(GL_UNIFORM_BUFFER, UniformBindingIndex_LightSource, _ubo,
                      _uboOffset_LightSource, _uniformBlockSize_LightSource);
    offSet += _uniformBlockSize_LightSource;
    offSet = align(offSet, uboOffsetAlignment);
    _uboOffset_Material = offSet;
    glBindBufferRange(GL_UNIFORM_BUFFER, UniformBindingIndex_Matrial, _ubo,
                      _uboOffset_Material, _uniformBlockSize_Material);
    
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) update
{
    // Update per frame constants here.
    
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
    GLvoid * pUniformBuffer = glMapBufferRange(GL_UNIFORM_BUFFER, 0, _uboBufferSize,
                                               GL_MAP_WRITE_BIT);
    // Copy Transform data to uniform buffer.
    memcpy((char *)pUniformBuffer + _uboOffset_Transforms,
           &_sceneTransforms, sizeof(_sceneTransforms));
    
    // Copy LightSource data to uniform buffer.
    memcpy((char *)pUniformBuffer + _uboOffset_LightSource,
           &_lightSource, sizeof(_lightSource));
    
    // Copy Material data to uniform buffer.
    memcpy((char *)pUniformBuffer + _uboOffset_Material,
           &_material, sizeof(_material));
    
    glUnmapBuffer(GL_UNIFORM_BUFFER);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
// View has requested a refresh, so draw next frame here
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    GLint width = static_cast<GLint>(_glkView.drawableWidth);
    GLint height = static_cast<GLint>(_glkView.drawableHeight);
    glViewport(0, 0, width, height);
    
    // Clear the framebuffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_shaderProgram);
    glBindVertexArray(_vao);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);

    VALIDATE_GL_PROGRAM(_shaderProgram);
    
    glDrawElements(GL_TRIANGLES, _numCubeIndices, GL_UNSIGNED_SHORT, nullptr);

    glBindVertexArray(0);
    glUseProgram(0);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    CHECK_GL_ERRORS;
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
    
    glDeleteBuffers(1, &_vbo_cube);
    glDeleteVertexArrays(1, &_vao);
    
    if (_shaderProgram) {
        glDeleteProgram(_shaderProgram);
        _shaderProgram = 0;
    }
}



@end // end ViewController


