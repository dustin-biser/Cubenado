//
//  CubenadoRenderer.mm
//

#import "CubenadoRenderer.h"

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


// Returns 'value' aligned to the next multiple of 'alignment'.
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


typedef std::string FileName;
typedef std::string PathToFile;
typedef std::unordered_map<FileName, PathToFile> AssetDirectory;



@interface CubenadoRenderer()

- (void) buildAssetDirectory;

- (void) loadShaders;

- (void) loadCubeVertexData;

- (void) loadVertexArrays;

- (void) loadUniforms;

- (void) loadTransformFeedbackBuffers;

- (void) setUBOBindings;


@end // @interface CubenadoRenderer
    

@implementation CubenadoRenderer {
    
    AssetDirectory _assetDirectory;
    
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
    
    
    FramebufferSize _framebufferSize;
    
    // Uniform Buffer Data
    GLuint _ubo;
    GLuint _uboBufferSize;
    Transforms _sceneTransforms;
    GLint _uniformBufferDataOffset_Transforms;
    
    LightSource _lightSource;
    GLint _uniformBufferDataOffset_LightSource;
    
    Material _material;
    GLint _uniformBufferDataOffset_Material;

}


//---------------------------------------------------------------------------------------
- (instancetype)initWithFramebufferSize:(FramebufferSize)framebufferSize
{
    self = [super init];
    if(self) {
        _framebufferSize = framebufferSize;
        [self initializeRenderer];
    }
    
    return self;
}


//---------------------------------------------------------------------------------------
- (void) initializeRenderer
{
    [self buildAssetDirectory];
    
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
- (void) loadUniforms
{
    float fovy = 45.0f;
    float aspect = static_cast<float>(_framebufferSize.width) / _framebufferSize.height;
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
    
    // Bind shader block index to uniform buffer binding index
    glUniformBlockBinding(_shaderProgram_Cube, blockIndex0, UniformBindingIndex_Transforms);
    glUniformBlockBinding(_shaderProgram_Cube, blockIndex1, UniformBindingIndex_LightSource);
    glUniformBlockBinding(_shaderProgram_Cube, blockIndex2, UniformBindingIndex_Matrial);
    
    GLint uniformBufferOffsetAlignment;
    glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &uniformBufferOffsetAlignment);
    
    const GLint sizeofTransforms = sizeof(Transforms);
    const GLint sizeofLightSource = sizeof(LightSource);
    const GLint sizeofMaterial = sizeof(Material);
    
    // Create Uniform Buffer
    glGenBuffers(1, &_ubo);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
    _uboBufferSize =  align(sizeofTransforms, uniformBufferOffsetAlignment) +
                      align(sizeofLightSource, uniformBufferOffsetAlignment) +
                      sizeofMaterial;
    glBufferData(GL_UNIFORM_BUFFER, _uboBufferSize, nullptr, GL_DYNAMIC_DRAW);
    
    // Map range of uniform buffer to each buffer binding index
    {
        GLint offSet = 0;
        _uniformBufferDataOffset_Transforms = offSet;
        glBindBufferRange(GL_UNIFORM_BUFFER,
                          UniformBindingIndex_Transforms,
                          _ubo,
                          _uniformBufferDataOffset_Transforms,
                          sizeof(Transforms));
        
        offSet += sizeofTransforms;
        offSet = align(offSet, uniformBufferOffsetAlignment);
        _uniformBufferDataOffset_LightSource = offSet;
        glBindBufferRange(GL_UNIFORM_BUFFER,
                          UniformBindingIndex_LightSource,
                          _ubo,
                          _uniformBufferDataOffset_LightSource,
                          sizeof(LightSource));
        
        offSet += sizeofLightSource;
        offSet = align(offSet, uniformBufferOffsetAlignment);
        _uniformBufferDataOffset_Material = offSet;
        glBindBufferRange(GL_UNIFORM_BUFFER,
                          UniformBindingIndex_Matrial,
                          _ubo,
                          _uniformBufferDataOffset_Material,
                          sizeofMaterial);
    }
    
    glBindBuffer(GL_UNIFORM_BUFFER, 0);
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
// Call once per frame, before [CubenadoRenderer render].
- (void) update:(NSInteger)timeSinceLastUpdate;
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
// Call once per frame, after [CubenadoRenderer update].
- (void)render: (FramebufferSize)framebufferSize
{
    glViewport(0, 0, framebufferSize.width, framebufferSize.height);
    
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


@end // @implementation CubenadoRenderer
