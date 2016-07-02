//
//  ViewController.m
//

#import "ViewController.h"

#import <string>
using std::string;

#import <vector>
using std::vector;

#import <unordered_map>
using std::unordered_map;

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/matrix_transform.hpp>

#import "ShaderProgram.hpp"


// Vertex Attribute Location Slots
const static GLuint ATTRIBUTE_POSITION = 0;
const static GLuint ATTRIBUTE_NORMAL   = 1;


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

- (void) buildAssetDirectory;

- (void) setupGL;

- (void) tearDownGL;

- (void) loadShaders;

- (void) loadCubeVertexData;

- (void) loadVertexArrays;

- (void) loadUniforms;

- (void) loadTransformFeedbackBuffers;

- (void) setUBOBindings;

@end

typedef std::string FileName;
typedef std::string PathToFile;

@implementation ViewController {
@private
    GLKView * _glkView;
    
    NSArray<NSURL *> * _assetUrls;
    std::unordered_map<FileName, PathToFile> _assetDirectory;

    ShaderProgram _shaderProgram_Cube;
    ShaderProgram _shaderProgram_TFUpdate;
    
    // Cube data
    GLuint _vao_cube;
    GLuint _vbo_cube;
    GLuint _indexBuffer_cube;
    GLsizei _numCubeIndices;
    
    // Transform Feedback source/destination buffers.
    struct TransformFeedbackBuffers {
        GLuint sourceBuffer;
        GLuint destBuffer;
    };
    TransformFeedbackBuffers _vbo_TFBuffers;
    
    
    GLsizei _framebufferWidth;
    GLsizei _framebufferHeight;
    
    
    // Uniform Buffer Data
    GLuint _ubo;
    GLuint _uboBufferSize;
    Transforms _sceneTransforms;
    GLint _uniformBufferDataOffset_Transforms;
    GLint _unifomBlockSize_Transforms;
    
    LightSource _lightSource;
    GLint _uniformBufferDataOffset_LightSource;
    GLint _uniformBlockSize_LightSource;
    
    Material _material;
    GLint _uniformBufferDataOffset_Material;
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
    
    [self buildAssetDirectory];
    
    [self setupGL];
}


//---------------------------------------------------------------------------------------
- (void) setupGL
{
    [EAGLContext setCurrentContext:self.eaglContext];
    
    [self loadShaders];

    [self loadCubeVertexData];
    
    [self loadTransformFeedbackBuffers];

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
- (void) loadCubeVertexData
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
- (void) loadTransformFeedbackBuffers
{
    glGenBuffers(2, &_vbo_TFBuffers.sourceBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vbo_TFBuffers.sourceBuffer);
    
    std::vector<glm::vec3> tfBufferData = {
        {0.0f, 0.0f, 0.0f}
    };
    
    size_t numBytes = tfBufferData.size() * sizeof(glm::vec3);
    glBufferData(GL_ARRAY_BUFFER, numBytes, tfBufferData.data(), GL_STATIC_DRAW);
    
    
    
    
    //-- Unbind target, and check for errors
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void)loadVertexArrays
{
    glGenVertexArrays(1, &_vao_cube);
    glBindVertexArray(_vao_cube);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer_cube);

    // Enable vertex attribute slots
    {
        glBindVertexArray(_vao_cube);
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        glEnableVertexAttribArray(ATTRIBUTE_NORMAL);
    }

    // Bind for use with glVertexAttribPointer().
    glBindBuffer(GL_ARRAY_BUFFER, _vbo_cube);
    
    // Position data mapping from VBO to vertex attribute slot
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset(0);
        glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, stride,
            reinterpret_cast<const GLvoid *>(startOffset));
    }
    
    // Normal data mapping from VBO to vertex attribute slot
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset = sizeof(Vertex::position);
        glVertexAttribPointer(ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, stride,
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
        memcpy((char *)pUniformBuffer + _uniformBufferDataOffset_Transforms,
               &_sceneTransforms, sizeof(_sceneTransforms));
        
        // Copy LightSource data to uniform buffer.
        memcpy((char *)pUniformBuffer + _uniformBufferDataOffset_LightSource,
               &_lightSource, sizeof(_lightSource));
        
        // Copy Material data to uniform buffer.
        memcpy((char *)pUniformBuffer + _uniformBufferDataOffset_Material,
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
    GLuint blockIndex0 = glGetUniformBlockIndex(_shaderProgram_Cube, "Transforms");
    GLuint blockIndex1 = glGetUniformBlockIndex(_shaderProgram_Cube, "LightSource");
    GLuint blockIndex2 = glGetUniformBlockIndex(_shaderProgram_Cube, "Material");
    
    // Query uniform block size
    glGetActiveUniformBlockiv(_shaderProgram_Cube, blockIndex0, GL_UNIFORM_BLOCK_DATA_SIZE,
            &_unifomBlockSize_Transforms);
    glGetActiveUniformBlockiv(_shaderProgram_Cube, blockIndex1, GL_UNIFORM_BLOCK_DATA_SIZE,
            &_uniformBlockSize_LightSource);
    glGetActiveUniformBlockiv(_shaderProgram_Cube, blockIndex2, GL_UNIFORM_BLOCK_DATA_SIZE,
            &_uniformBlockSize_Material);
    
    
    // Bind shader block index to uniform buffer binding index
    glUniformBlockBinding(_shaderProgram_Cube, blockIndex0, UniformBindingIndex_Transforms);
    glUniformBlockBinding(_shaderProgram_Cube, blockIndex1, UniformBindingIndex_LightSource);
    glUniformBlockBinding(_shaderProgram_Cube, blockIndex2, UniformBindingIndex_Matrial);
    
    GLint uniformBufferOffsetAlignment;
    glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &uniformBufferOffsetAlignment);
    
    // Create Uniform Buffer
    glGenBuffers(1, &_ubo);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
    _uboBufferSize =  align(_unifomBlockSize_Transforms, uniformBufferOffsetAlignment) +
                      align(_uniformBlockSize_LightSource, uniformBufferOffsetAlignment) +
                      _uniformBlockSize_Material;
    glBufferData(GL_UNIFORM_BUFFER, _uboBufferSize, nullptr, GL_DYNAMIC_DRAW);
    
    // Map range of uniform buffer to uniform buffer binding index
    GLint offSet = 0;
    _uniformBufferDataOffset_Transforms = offSet;
    glBindBufferRange(GL_UNIFORM_BUFFER,
                      UniformBindingIndex_Transforms,
                      _ubo,
                      _uniformBufferDataOffset_Transforms,
                      _unifomBlockSize_Transforms
    );
    
    offSet += _unifomBlockSize_Transforms;
    offSet = align(offSet, uniformBufferOffsetAlignment);
    _uniformBufferDataOffset_LightSource = offSet;
    glBindBufferRange(GL_UNIFORM_BUFFER,
                      UniformBindingIndex_LightSource,
                      _ubo,
                      _uniformBufferDataOffset_LightSource,
                      _uniformBlockSize_LightSource
    );
    
    offSet += _uniformBlockSize_LightSource;
    offSet = align(offSet, uniformBufferOffsetAlignment);
    _uniformBufferDataOffset_Material = offSet;
    glBindBufferRange(GL_UNIFORM_BUFFER,
                      UniformBindingIndex_Matrial,
                      _ubo,
                      _uniformBufferDataOffset_Material,
                      _uniformBlockSize_Material
    );
    
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
    memcpy((char *)pUniformBuffer + _uniformBufferDataOffset_Transforms,
           &_sceneTransforms, sizeof(_sceneTransforms));
    
    // Copy LightSource data to uniform buffer.
    memcpy((char *)pUniformBuffer + _uniformBufferDataOffset_LightSource,
           &_lightSource, sizeof(_lightSource));
    
    // Copy Material data to uniform buffer.
    memcpy((char *)pUniformBuffer + _uniformBufferDataOffset_Material,
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
    
    _shaderProgram_Cube.enable();
    glBindVertexArray(_vao_cube);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);

    glDrawElements(GL_TRIANGLES, _numCubeIndices, GL_UNSIGNED_SHORT, nullptr);

    _shaderProgram_Cube.disable();
    glBindVertexArray(0);
    glUseProgram(0);
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void) buildAssetDirectory
{
    NSArray<NSURL *> * glslAssets =
            [[NSBundle mainBundle] URLsForResourcesWithExtension:@"glsl"
                                                    subdirectory:nil];
    
    std::pair<FileName, PathToFile> pair;
    for(NSURL * url in glslAssets) {
        NSString * fileName = [[url path] lastPathComponent];
        NSString * pathToFile = [url path];
        pair.first = std::string([fileName UTF8String]);
        pair.second = std::string([pathToFile UTF8String]);
        
        _assetDirectory.insert(pair);
    }
}


//---------------------------------------------------------------------------------------
- (void)loadShaders
{
    //-- Create Cube Shader:
    {
        _shaderProgram_Cube.generateProgramObject();
        _shaderProgram_Cube.attachVertexShader(_assetDirectory["VertexShader.glsl"]);
        _shaderProgram_Cube.attachFragmentShader(_assetDirectory["FragmentShader.glsl"]);
        _shaderProgram_Cube.link();
    }
    
    
    //-- Create TFUpdate Shader:
    {
        _shaderProgram_TFUpdate.generateProgramObject();
        _shaderProgram_TFUpdate.attachVertexShader(_assetDirectory["TFUpdate.glsl"]);
        _shaderProgram_TFUpdate.attachFragmentShader(_assetDirectory["TFUpdateFrag.glsl"]);
        
        const GLchar* feedbackVaryings[] = { "VsOut.position" };
        glTransformFeedbackVaryings(_shaderProgram_TFUpdate, 1, feedbackVaryings, GL_INTERLEAVED_ATTRIBS);
        
        _shaderProgram_TFUpdate.link();
    }
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
    glDeleteVertexArrays(1, &_vao_cube);
    
}


@end // end ViewController
