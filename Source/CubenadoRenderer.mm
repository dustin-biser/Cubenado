//
//  CubenadoRenderer.mm
//

#import "CubenadoRenderer.h"

#import <GLKit/GLKit.h>

#import <vector>
using std::vector;

#import <unordered_map>
using std::unordered_map;

#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>

#import "ShaderProgram.hpp"
#import "AssetDirectory.hpp"
#import "ParticleSystem.hpp"
#import "NormRand.hpp"
#import "VertexAttributeDefines.h"


struct Transforms {
    glm::mat4 modelMatrix;
    glm::mat4 viewMatrix;
    glm::mat4 projectMatrix;
    glm::mat4 normalMatrix;
};
static const GLuint UniformBindingIndex_Transforms = 0;


struct LightSource {
    glm::vec4 position_worldSpace;
    glm::vec4 rgbIntensity;
};
static const GLuint UniformBindingIndex_LightSource = 1;


struct Material {
    glm::vec4 Ka; // Coefficients of ambient reflectivity
    glm::vec4 Kd; // Coefficients of diffuse reflectivity
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



@interface CubenadoRenderer()

- (void) initializeRendererWith: (uint)numCubes
                       maxCubes: (uint)maxCubes
                 cubeRandomness: (float) cubeRandomness;

- (void) buildAssetDirectory;

- (void) loadShaders;

- (void) loadCubeVertexData: (uint)maxCubes;

- (void) loadGroundPlaneVertexData;

- (void) loadGroundPlaneUniforms;

- (void) initVertexAttribMappingsForGoundPlane;

- (void) initVertexAttribMappingsForCube;

- (void) loadCubeUniforms;

- (void) loadShadowMapUniforms;

- (void) setUBOBindings;

- (void) setParticlePositionVboAttribMapping: (ParticleSystem *)particleSystem
                                     withVao: (GLuint)vao;

- (void) setViewportIfViewSizeChanged: (GLKView *)glkView;

- (void) setDefaultGLState;

- (void) initShadowPassResources;

- (void) initShadowMapMatrices;

- (void) shadowMapPass;
    
- (void) renderCubes;

- (void) renderGroundPlane;

@end // @interface CubenadoRenderer
    

@implementation CubenadoRenderer {
    
    AssetDirectory _assetDirectory;
    
    FramebufferSize _framebufferSize;
    
    std::shared_ptr<ParticleSystem> _particleSystem;
    
    // Cube data
    GLuint _vao_cube;
    GLuint _vbo_cube;
    GLuint _indexBuffer_cube;
    GLsizei _numCubeIndices;
    ShaderProgram _shaderProgram_cube;
    
    // Uniform Buffer Data
    GLuint _ubo;
    GLuint _uboBufferSize;
    Transforms _sceneTransforms;
    GLint _uniformBufferDataOffset_Transforms;
    
    LightSource _lightSource;
    GLint _uniformBufferDataOffset_LightSource;
    
    Material _material;
    GLint _uniformBufferDataOffset_Material;
    
    struct CubeOrientation {
        glm::vec3 axis;
        float maxAngle;
    };
    
    // Cube orientation based on cube randomness
    GLint _uniformLocation_cubeRandomness;
    float _cubeRandomness;
    GLuint _vbo_orientation;
    
    
    struct ShadowMapUniformLocations
    {
        GLint modelMatrix;
        GLint lightViewMatrix;
        GLint lightProjectMatrix;
        GLint cubeRandomness;
    };
    
    // Shadow map
    GLuint _texture_shadowMap;
    CGSize _shadowMapSize;
    GLuint _framebuffer_shadowMap;
    ShaderProgram _shaderProgram_shadowMap;
    glm::mat4 _lightViewMatrix;
    glm::mat4 _lightProjectMatrix;
    glm::mat4 _shadowMatrix;
    ShadowMapUniformLocations _uniformLocations_shadowMap;
    
    
    // Ground plane
    GLuint _vao_groundPlane;
    GLuint _vbo_groundPlane;
    GLuint _indexBuffer_groundPlane;
    ShaderProgram _shaderProgram_groundPlane;
    GLsizei _numGroundPlaneIndices;
    
    struct GroundPlaneUniformLocations
    {
        GLint modelMatrix;
        GLint viewProjectMatrix;
        GLint normalMatrix;
        GLint shadowMatrix;
        GLint sampler2dShadowmap;
    };
    GroundPlaneUniformLocations _uniformLocations_groundPlane;
}


//---------------------------------------------------------------------------------------
- (instancetype)initWithFramebufferSize: (FramebufferSize)framebufferSize
                               numCubes: (uint) numCubes
                               maxCubes: (uint) maxCubes
                         cubeRandomness: (float) cubeRandomness
{
    self = [super init];
    if(self) {
        _framebufferSize = framebufferSize;
        
        [self initializeRendererWith: numCubes
                            maxCubes: maxCubes
                      cubeRandomness: cubeRandomness];
    }
    
    return self;
}


//---------------------------------------------------------------------------------------
- (void) initializeRendererWith: (uint)numCubes
                       maxCubes: (uint)maxCubes
                 cubeRandomness: (float) cubeRandomness
{
    _cubeRandomness = cubeRandomness;
    
    [self buildAssetDirectory];
    
    [self loadShaders];
    
    [self loadCubeVertexData: maxCubes];
    
    [self initVertexAttribMappingsForCube];
    
    [self setUBOBindings];
    
    [self loadCubeUniforms];
    
    [self setDefaultGLState];
    
    [self initShadowPassResources];
    
    
    const uint numActiveParticles = numCubes;
    const uint maxParticles = maxCubes;
    _particleSystem = std::make_shared<ParticleSystem>(_assetDirectory,
                                                       numActiveParticles,
                                                       maxParticles,
                                                       cubeRandomness);
    
    [self initShadowMapMatrices];
    
    [self loadShadowMapUniforms];

    [self loadGroundPlaneVertexData];

    [self initVertexAttribMappingsForGoundPlane];
    
    [self loadGroundPlaneUniforms];
}

//---------------------------------------------------------------------------------------
- (void) buildAssetDirectory
{
    // Gather all shader assets URLs in mainBundle with file ending in .glsl
    NSArray<NSURL *> * glslAssets =
            [[NSBundle mainBundle] URLsForResourcesWithExtension:@"glsl"
                                                    subdirectory:nil];
    
    // Map file name to file path and insert into _assetDirectory.
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
- (void) setDefaultGLState
{
    // Clear values
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClearDepthf(1.0f);
    
    // Depth settings
    glEnable(GL_DEPTH_TEST);
    glDepthMask(GL_TRUE);
    glDepthFunc(GL_LEQUAL);
    glDepthRangef(0.0f, 1.0f);
    
    // Enable backface culling
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) loadCubeVertexData: (uint) maxCubes
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
    
    
    // Load cube orientation data
    {
        glGenBuffers(1, &_vbo_orientation);
        
        std::vector<CubeOrientation> orientationData(maxCubes);
        
        glm::vec3 axis;
        const float maxAngle = static_cast<float>(M_PI * 0.5f);
        for(int i(0); i < maxCubes; ++i) {
            axis.x = rand0to1();
            axis.y = rand0to1();
            axis.z = rand0to1();
            orientationData[i].axis = glm::normalize(axis);
            orientationData[i].maxAngle = maxAngle;
        }
        

        glBindBuffer(GL_ARRAY_BUFFER, _vbo_orientation);
        
        GLsizeiptr numBytes = orientationData.size() * sizeof(CubeOrientation);
        glBufferData(GL_ARRAY_BUFFER, numBytes, orientationData.data(), GL_STATIC_DRAW);
        
        CHECK_GL_ERRORS;
    }
}


//---------------------------------------------------------------------------------------
- (void) loadGroundPlaneVertexData
{
    std::vector<Vertex> vertexData = {
        // Positions             Normals
        { -0.5f,  0.0f,  0.5f,   0.0f,  1.0f,  0.0f}, // 0
        {  0.5f,  0.0f,  0.5f,   0.0f,  1.0f,  0.0f}, // 1
        {  0.5f,  0.0f, -0.5f,   0.0f,  1.0f,  0.0f}, // 2
        { -0.5f,  0.0f, -0.5f,   0.0f,  1.0f,  0.0f}  // 3
    };
    
    // Load Vertex Data into Array Buffer for ground plane.
    {
        glGenBuffers(1, &_vbo_groundPlane);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_groundPlane);
        const GLsizeiptr numBytes = sizeof(Vertex) * vertexData.size();
        glBufferData(GL_ARRAY_BUFFER, numBytes, vertexData.data(), GL_STATIC_DRAW);
        
        CHECK_GL_ERRORS;
    }
    
    std::vector<Index> indexData = {
        0,2,3, 0,1,2
    };
    
    _numGroundPlaneIndices = static_cast<GLsizei>(indexData.size());
    
    // Load Index Data into Element Array Buffer for ground plane.
    {
        glGenBuffers(1, &_indexBuffer_groundPlane);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer_groundPlane);
        size_t numBytes = indexData.size() * sizeof(Index);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numBytes, indexData.data(), GL_STATIC_DRAW);
        
        CHECK_GL_ERRORS;
    }
}


//---------------------------------------------------------------------------------------
- (void) loadGroundPlaneUniforms
{
    // Query uniform locations
    {
        _uniformLocations_groundPlane.modelMatrix =
            _shaderProgram_groundPlane.getUniformLocation("modelMatrix");
        
        _uniformLocations_groundPlane.viewProjectMatrix =
            _shaderProgram_groundPlane.getUniformLocation("viewProjectMatrix");
        
        _uniformLocations_groundPlane.shadowMatrix =
            _shaderProgram_groundPlane.getUniformLocation("shadowMatrix");
        
        _uniformLocations_groundPlane.sampler2dShadowmap =
            _shaderProgram_groundPlane.getUniformLocation("shadowMap");
        
        CHECK_GL_ERRORS;
    }
    
    glm::mat4 modelMatrix = glm::scale(glm::mat4(), glm::vec3(200.0f, 1.0f, 200.0f));
    modelMatrix = glm::translate(glm::mat4(), glm::vec3(0.0f, -9.0f, -50.0f)) * modelMatrix;
    
    glm::mat4 viewMatrix = _sceneTransforms.viewMatrix;
    glm::mat4 viewProjectMatrix = _sceneTransforms.projectMatrix * viewMatrix;
    
    glm::mat4 shadowMatrix = _shadowMatrix;
    
    // Upload shader uniform data
    {
        _shaderProgram_groundPlane.enable();
        
        glUniformMatrix4fv(_uniformLocations_groundPlane.modelMatrix, 1, GL_FALSE,
                           &modelMatrix[0][0]);
        
        glUniformMatrix4fv(_uniformLocations_groundPlane.viewProjectMatrix, 1, GL_FALSE,
                           &viewProjectMatrix[0][0]);
        
        glUniformMatrix4fv(_uniformLocations_groundPlane.shadowMatrix, 1, GL_FALSE,
                           &shadowMatrix[0][0]);
        
        const GLint textureUnit0(0);
        glUniform1i(_uniformLocations_groundPlane.sampler2dShadowmap, textureUnit0);
        
        
        CHECK_GL_ERRORS;
    }
    
    
}


//---------------------------------------------------------------------------------------
- (void)initVertexAttribMappingsForCube
{
    glGenVertexArrays(1, &_vao_cube);
    glBindVertexArray(_vao_cube);
    
    // Record the index buffer to be used
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer_cube);
    
    // Enable vertex attribute slots
    {
        glBindVertexArray(_vao_cube);
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        glEnableVertexAttribArray(ATTRIBUTE_NORMAL);
        glEnableVertexAttribArray(ATTRIBUTE_INSTANCE_1);
        
        CHECK_GL_ERRORS;
    }
    
    
    // Position data
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset(0);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_cube);
        glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, stride,
                              reinterpret_cast<const GLvoid *>(startOffset));
        CHECK_GL_ERRORS;
    }
    
    // Normal data
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset = sizeof(Vertex::position);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_cube);
        glVertexAttribPointer(ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, stride,
                              reinterpret_cast<const GLvoid *>(startOffset));
        CHECK_GL_ERRORS;
    }
    
    // Cube orientation
    {
        GLint stride = 0;
        GLint startOffset = 0;
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_orientation);
        glVertexAttribPointer(ATTRIBUTE_INSTANCE_1, 4, GL_FLOAT, GL_FALSE, stride,
                              reinterpret_cast<const GLvoid *>(startOffset));
        
        // Advance attribute once per instance.
        glVertexAttribDivisor(ATTRIBUTE_INSTANCE_1, 1);
        
        CHECK_GL_ERRORS;
    }
    
    // Unbind vao
    glBindVertexArray(0);
}


//---------------------------------------------------------------------------------------
- (void) initVertexAttribMappingsForGoundPlane
{
    glGenVertexArrays(1, &_vao_groundPlane);
    glBindVertexArray(_vao_groundPlane);
    
    // Record the index buffer to be used
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer_groundPlane);

    // Enable vertex attribute slots
    {
        glEnableVertexAttribArray(ATTRIBUTE_POSITION);
        glEnableVertexAttribArray(ATTRIBUTE_NORMAL);

        CHECK_GL_ERRORS;
    }

    // Map position data from vertex buffer to vertex attribute slot.
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset(0);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_groundPlane);
        glVertexAttribPointer(ATTRIBUTE_POSITION, 3, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(startOffset));

        CHECK_GL_ERRORS;
    }

    // Map normal data from vertex buffer to vertex attribute slot.
    {
        GLint stride = sizeof(Vertex);
        GLint startOffset = sizeof(Vertex::position);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_groundPlane);
        glVertexAttribPointer(ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(startOffset));

        CHECK_GL_ERRORS;
    }
    
    // Unbind vao
    glBindVertexArray(0);
}

//---------------------------------------------------------------------------------------
- (void) initShadowPassResources
{
    // Create Shadow map texture
    {
        glGenTextures(1, &_texture_shadowMap);
        
        glBindTexture(GL_TEXTURE_2D, _texture_shadowMap);
        
        //FIXME: warning, at program startup framebufferSize is only a fraction of actual size
        // Should create texture at first run of CubenadoRenderer:update:
        _shadowMapSize.width = 2.0f * _framebufferSize.width;
        _shadowMapSize.height = 2.0f * _framebufferSize.height;
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT32F, _shadowMapSize.width,
                     _shadowMapSize.height, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_COMPARE_FUNC, GL_LESS);
        
        
        glBindTexture(GL_TEXTURE_2D, 0);
        CHECK_GL_ERRORS;
    }
    
    
    // Create and set up the framebuffer object
    {
        glGenFramebuffers(1, &_framebuffer_shadowMap);
        glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer_shadowMap);
        
        GLint level0 = 0;
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_2D,
                               _texture_shadowMap, level0);
        
        CHECK_FRAMEBUFFER_COMPLETENESS;
        
        // Prevent rendering to color buffers.
        GLenum drawBuffers[] = { GL_NONE };
        glDrawBuffers(1, drawBuffers);
        
        // Revert back to default framebuffer.
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        CHECK_GL_ERRORS;
    }
    
}


//---------------------------------------------------------------------------------------
- (void) initShadowMapMatrices
{
    glm::vec3 eye = _lightSource.position_worldSpace;
    glm::vec3 center = glm::vec3(4.0f, -5.0f, -40.0f);
    glm::vec3 up(0.0f, 1.0f, 0.0);
    
    _lightViewMatrix = glm::lookAt(eye, center, up);
    
    float fovy = 45.0f;
    float aspect = static_cast<float>(_framebufferSize.width) / _framebufferSize.height;
    _lightProjectMatrix = glm::perspective(glm::radians(fovy), aspect, 0.1f, 500.0f);
    
    
    // For scaling + translating shadow map coordinate
    glm::mat4 biasMatrix = {
        glm::vec4(0.5f, 0.0f, 0.0f, 0.0f), // column 0
        glm::vec4(0.0f, 0.5f, 0.0f, 0.0f), // column 1
        glm::vec4(0.0f, 0.0f, 0.5f, 0.0f), // column 2
        glm::vec4(0.5f, 0.5f, 0.5f, 1.0f)  // column 3
    };
    
    _shadowMatrix = biasMatrix * _lightProjectMatrix * _lightViewMatrix;
}

//---------------------------------------------------------------------------------------
- (void) loadShaders
{
    // Create Cube ShaderProgram
    {
        _shaderProgram_cube.generateProgramObject();
        _shaderProgram_cube.attachVertexShader(_assetDirectory.at("CubeVS.glsl"));
        _shaderProgram_cube.attachFragmentShader(_assetDirectory.at("CubeFS.glsl"));
        _shaderProgram_cube.link();
        
        
        // Query Cube Randomness uniform location
        _uniformLocation_cubeRandomness =
            _shaderProgram_cube.getUniformLocation("cubeRandomness");
    }
    
    
    // Create Shadow Map ShaderProgram
    {
        _shaderProgram_shadowMap.generateProgramObject();
        _shaderProgram_shadowMap.attachVertexShader(_assetDirectory.at("ShadowMapVS.glsl"));
        _shaderProgram_shadowMap.attachFragmentShader(_assetDirectory.at("ShadowMapFS.glsl"));
        _shaderProgram_shadowMap.link();
        
        // Query uniform locations
        _uniformLocations_shadowMap.cubeRandomness =
            _shaderProgram_shadowMap.getUniformLocation("cubeRandomness");
        
        _uniformLocations_shadowMap.modelMatrix =
            _shaderProgram_shadowMap.getUniformLocation("modelMatrix");
        
        _uniformLocations_shadowMap.lightViewMatrix =
            _shaderProgram_shadowMap.getUniformLocation("lightViewMatrix");
        
        _uniformLocations_shadowMap.lightProjectMatrix =
            _shaderProgram_shadowMap.getUniformLocation("lightProjectMatrix");
    }
    
    
    // Create Ground Plane ShaderProgram
    {
        _shaderProgram_groundPlane.generateProgramObject();
        _shaderProgram_groundPlane.attachVertexShader(_assetDirectory.at("GroundPlaneVS.glsl"));
        _shaderProgram_groundPlane.attachFragmentShader(_assetDirectory.at("GroundPlaneFS.glsl"));
        _shaderProgram_groundPlane.link();
    }
}


//---------------------------------------------------------------------------------------
- (void) loadCubeUniforms
{
    float fovy = 45.0f;
    float aspect = static_cast<float>(_framebufferSize.width) / _framebufferSize.height;
    glm::mat4 projectionMatrix = glm::perspective(glm::radians(fovy), aspect, 1.0f, 400.0f);
    
    
    glm::vec3 cameraLocation = {0.0f, 0.0f, 10.0f};
    glm::mat4 viewMatrix = glm::lookAt (
        cameraLocation,               // eye
        glm::vec3{0.0f, 0.0f, -50.0f}, // center
        glm::vec3{0.0f, 1.0f, 0.0f}   // up
    );
    
    float angle = M_PI * 0.25f;
    glm::mat4 rotMatrix = glm::rotate(glm::mat4(), angle, glm::vec3(1.0f, 1.0f, 1.0f));
    glm::mat4 modelMatrix = rotMatrix;
    
    _sceneTransforms.modelMatrix = modelMatrix;
    _sceneTransforms.viewMatrix = viewMatrix;
    _sceneTransforms.projectMatrix = projectionMatrix;
    
    // modelViewMatrix scale is uniform, so inverse == transpose
    _sceneTransforms.normalMatrix = modelMatrix;
    
    
    // Convert lightSource position to EyeSpace.
    _lightSource.position_worldSpace = glm::vec4(-6.0f, 16.0f, 25.0f, 1.0f);
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
- (void) loadShadowMapUniforms
{
    _shaderProgram_shadowMap.enable();
    
    glUniformMatrix4fv(_uniformLocations_shadowMap.modelMatrix, 1, GL_FALSE,
                       &_sceneTransforms.modelMatrix[0][0]);
    
    glUniformMatrix4fv(_uniformLocations_shadowMap.lightViewMatrix, 1, GL_FALSE,
                       &_lightViewMatrix[0][0]);
    
    glUniformMatrix4fv(_uniformLocations_shadowMap.lightProjectMatrix, 1, GL_FALSE,
                       &_lightProjectMatrix[0][0]);
    
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void) setUBOBindings
{
    // Query uniform block indices
    GLuint blockIndex0 = glGetUniformBlockIndex(_shaderProgram_cube, "Transforms");
    GLuint blockIndex1 = glGetUniformBlockIndex(_shaderProgram_cube, "LightSource");
    GLuint blockIndex2 = glGetUniformBlockIndex(_shaderProgram_cube, "Material");
    
    // Bind shader block index to uniform buffer binding index
    glUniformBlockBinding(_shaderProgram_cube, blockIndex0, UniformBindingIndex_Transforms);
    glUniformBlockBinding(_shaderProgram_cube, blockIndex1, UniformBindingIndex_LightSource);
    glUniformBlockBinding(_shaderProgram_cube, blockIndex2, UniformBindingIndex_Matrial);
    
    GLint uniformBufferOffsetAlignment;
    glGetIntegerv(GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, &uniformBufferOffsetAlignment);
    
    const GLint sizeofTransforms = sizeof(Transforms);
    const GLint sizeofLightSource = sizeof(LightSource);
    const GLint sizeofMaterial = sizeof(Material);
    
    // Create Uniform Buffer
    glGenBuffers(1, &_ubo);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
    // UBO size much account for buffer offset alignment restriction
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
- (void) updatePerFrameUniforms
{
    // Update cube randomness uniform
    _shaderProgram_cube.enable();
    glUniform1f(_uniformLocation_cubeRandomness, _cubeRandomness);
    CHECK_GL_ERRORS;
    
    _shaderProgram_shadowMap.enable();
    glUniform1f(_uniformLocations_shadowMap.cubeRandomness, _cubeRandomness);
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void) setParticlePositionVboAttribMapping: (ParticleSystem *)particleSystem
                                     withVao: (GLuint)vao
{
    // Position data mapping from ParticleSystem VBO to vertex attribute slot
    glBindVertexArray(vao);
    glEnableVertexAttribArray(ATTRIBUTE_INSTANCE_0);
    
    glBindBuffer(GL_ARRAY_BUFFER, particleSystem->particlePositionsVbo());
    
    
    VertexAttributeDescriptor descriptor =
        particleSystem->getVertexDescriptorForParticlePositions();
    
    glVertexAttribPointer(ATTRIBUTE_INSTANCE_0, descriptor.numComponents, descriptor.type,
                          GL_FALSE, descriptor.stride, descriptor.offset);
    
    // Advance attribute once per instance.
    glVertexAttribDivisor(ATTRIBUTE_INSTANCE_0, 1);
    
    CHECK_GL_ERRORS;
}



//---------------------------------------------------------------------------------------
// Call once per frame, before CubenadoRenderer:renderWithFrameBuffer:
- (void) update:(NSTimeInterval)timeSinceLastUpdate;
{
    [self updatePerFrameUniforms];
    
    _particleSystem->update(timeSinceLastUpdate);
}


//---------------------------------------------------------------------------------------
- (void) setViewportIfViewSizeChanged: (GLKView *)glkView
{
    GLint width = static_cast<GLint>(glkView.drawableWidth);
    GLint height = static_cast<GLint>(glkView.drawableHeight);
    
    const bool widthChanged(_framebufferSize.width != width);
    const bool heightChanged(_framebufferSize.height != height);
    
    if(widthChanged || heightChanged) {
        _framebufferSize.width = width;
        _framebufferSize.height = height;
        glViewport(0, 0, _framebufferSize.width, _framebufferSize.height);
    }
}


//---------------------------------------------------------------------------------------
// Call once per frame, after CubenadoRenderer:update:
- (void) renderWithGLKView: (GLKView *)glkView;
{
    
    [self setParticlePositionVboAttribMapping: _particleSystem.get()
                                      withVao: _vao_cube];
    
    [self shadowMapPass];
    
    [self setViewportIfViewSizeChanged: glkView];
    
    // Bind the GlkView framebuffer for rendering.
    [glkView bindDrawable];
    
    // Clear framebuffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self renderCubes];
    
    [self renderGroundPlane];
}


//---------------------------------------------------------------------------------------
- (void) shadowMapPass
{
    glPushGroupMarkerEXT(0, "Shadow Pass");
    
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer_shadowMap);
    
    glViewport(0, 0, _shadowMapSize.width, _shadowMapSize.height);
    glClear(GL_DEPTH_BUFFER_BIT);
    
    glCullFace(GL_FRONT);
    
    _shaderProgram_shadowMap.enable();
    glBindVertexArray(_vao_cube);
    
    const GLuint numInstances = _particleSystem->numActiveParticles();
    glDrawElementsInstanced(GL_TRIANGLES, _numCubeIndices, GL_UNSIGNED_SHORT, nullptr,
                            numInstances);
    
    
    // Restore default settings.
    glCullFace(GL_BACK);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    CHECK_GL_ERRORS;
    glPopGroupMarkerEXT();
}


//---------------------------------------------------------------------------------------
- (void) renderCubes
{
    glPushGroupMarkerEXT(0, "Render Cubes");
    
    _shaderProgram_cube.enable();
    glBindVertexArray(_vao_cube);
    glBindBuffer(GL_UNIFORM_BUFFER, _ubo);
    
    const GLuint numInstances = _particleSystem->numActiveParticles();
    glDrawElementsInstanced(GL_TRIANGLES, _numCubeIndices, GL_UNSIGNED_SHORT, nullptr,
                            numInstances);
    
    CHECK_GL_ERRORS;
    glPopGroupMarkerEXT();
}


//---------------------------------------------------------------------------------------
- (void) renderGroundPlane
{
    glPushGroupMarkerEXT(0, "Render Ground Plane");
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture_shadowMap);
    
    _shaderProgram_groundPlane.enable();
    glBindVertexArray(_vao_groundPlane);
    
    glDrawElements(GL_TRIANGLES, _numGroundPlaneIndices, GL_UNSIGNED_SHORT, nullptr);
    
    CHECK_GL_ERRORS;
    glPopGroupMarkerEXT();
}


//---------------------------------------------------------------------------------------
- (void) setNumCubes: (uint)numCubes
{
    _particleSystem->setNumActiveParticles(numCubes);
}


//---------------------------------------------------------------------------------------
- (void) setCubeRandomness: (float)cubeRandomness
{
    _cubeRandomness = cubeRandomness;
    
    // Update particle system randomness as well.
    _particleSystem->setParticleRandomness(cubeRandomness);
}


@end // @implementation CubenadoRenderer
