//
// ShaderProgram.cpp
//

#import "ShaderProgram.hpp"

#include <fstream>
using std::ifstream;

#include <iostream>
using std::endl;
using std::cout;
using std::cerr;

#include <string>
using std::string;

#include <sstream>
using std::stringstream;

#include <vector>
using std::vector;



class ShaderProgramImpl {
private:
    friend class ShaderProgram;
    
    GLuint programObject;
    
    std::vector<GLuint> shaderObjects;
    
    
    ShaderProgramImpl();
    
    ~ShaderProgramImpl();
    
    void attachShader(const char * filePath, GLenum shaderType);
    
    void checkCompilationStatus(GLuint shaderObject);
    
    void checkLinkStatus();
    
    GLuint createShader(GLenum shaderType);
    
    void compileShader(GLuint shaderObject, const std::string & shader);
    
    void extractSourceCode(std::string & shaderSource, const char * filePath);
    
    void releaseShaderObjects();
    
    void link();

};

//------------------------------------------------------------------------------------
ShaderProgramImpl::ShaderProgramImpl()
        : programObject(0)
{
    
}


//------------------------------------------------------------------------------------
ShaderProgram::ShaderProgram()
{
    impl = new ShaderProgramImpl();
}


//------------------------------------------------------------------------------------
void ShaderProgram::generateProgramObject() {
    auto & programObject = impl->programObject;
    if(programObject == 0) {
        programObject = glCreateProgram();
    }
}


//------------------------------------------------------------------------------------
void ShaderProgram::attachVertexShader (
    const std::string & filePath
) {
    impl->attachShader(filePath.c_str(), GL_VERTEX_SHADER);
}


//------------------------------------------------------------------------------------
void ShaderProgram::attachFragmentShader (
    const std::string & filePath
) {
    impl->attachShader(filePath.c_str(), GL_FRAGMENT_SHADER);
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::attachShader (
    const char * filePath,
    GLenum shaderType
) {
    GLuint shaderObject = glCreateShader(shaderType);
    CHECK_GL_ERRORS;

    shaderObjects.push_back(shaderObject);

    std::string shaderSourceCode;
    extractSourceCode(shaderSourceCode, filePath);
    compileShader(shaderObject, shaderSourceCode);
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::extractSourceCode (
    string & shaderSource,
    const char * filePath
) {
    std::ifstream file;

    file.open(filePath);
    if (!file) {
        stringstream strStream;
        strStream << "Error -- Failed to open file: " << filePath << endl;
        std::cerr << strStream.str();
    }

    std::stringstream strBuffer;
    std::string str;

    while(file.good()) {
        getline(file, str, '\r');
        strBuffer << str;
    }
    file.close();
    
    // Append null terminator.
    strBuffer << '\0';

    shaderSource = strBuffer.str();
}


//------------------------------------------------------------------------------------
void ShaderProgram::link()
{
    impl->link();
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::link()
{
    for(auto shaderObject : shaderObjects) {
        glAttachShader(programObject, shaderObject);
    }

    glLinkProgram(programObject);
    
    checkLinkStatus();
    releaseShaderObjects();
    CHECK_GL_ERRORS;
}


//------------------------------------------------------------------------------------
ShaderProgram::~ShaderProgram()
{
    delete impl;
    impl = nullptr;
}


//------------------------------------------------------------------------------------
ShaderProgramImpl::~ShaderProgramImpl()
{
    glDeleteProgram(programObject);
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::releaseShaderObjects() {
    for(auto shaderObject : shaderObjects) {
        glDetachShader(programObject, shaderObject);
        glDeleteShader(shaderObject);
    }
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::compileShader (
    GLuint shaderObject,
    const string & shaderSourceCode
) {
    const char * sourceCodeStr = shaderSourceCode.c_str();
    glShaderSource(shaderObject, 1, (const GLchar **)&sourceCodeStr, NULL);

    glCompileShader(shaderObject);
    checkCompilationStatus(shaderObject);
    
    CHECK_GL_ERRORS;
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::checkCompilationStatus (
    GLuint shaderObject
) {
    GLint compileSuccess;

    glGetShaderiv(shaderObject, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLint errorMessageLength;
        // Get the length in chars of the compilation error message.
        glGetShaderiv(shaderObject, GL_INFO_LOG_LENGTH, &errorMessageLength);

        // Retrieve the compilation error message.
        GLchar errorMessage[errorMessageLength + 1]; // Add 1 for null terminator
        glGetShaderInfoLog(shaderObject, errorMessageLength, NULL, errorMessage);

        std::string message = "Error Compiling Shader: ";
        message += errorMessage;

        std::cerr << message << std::endl;
    }
}


//------------------------------------------------------------------------------------
void ShaderProgram::enable() const {
    glUseProgram(impl->programObject);
    CHECK_GL_ERRORS;
}


//------------------------------------------------------------------------------------
void ShaderProgram::disable() const {
    glUseProgram((GLuint)NULL);
    CHECK_GL_ERRORS;
}


//------------------------------------------------------------------------------------
void ShaderProgramImpl::checkLinkStatus()
{
    GLint linkSuccess;

    glGetProgramiv(programObject, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLint errorMessageLength;
        // Get the length in chars of the link error message.
        glGetProgramiv(programObject, GL_INFO_LOG_LENGTH, &errorMessageLength);

        // Retrieve the link error message.
        GLchar errorMessage[errorMessageLength];
        glGetProgramInfoLog(programObject, errorMessageLength, NULL, errorMessage);

        std::stringstream strStream;
        strStream << "Error Linking Shaders: " << errorMessage << std::endl;
        std::cerr << strStream.str();
    }
}


//------------------------------------------------------------------------------------
GLuint ShaderProgram::programObject() const
{
    return impl->programObject;
}


//------------------------------------------------------------------------------------
GLint ShaderProgram::getUniformLocation (
    const char * uniformName
) const
{
    GLint result =
        glGetUniformLocation(impl->programObject, (const GLchar *)uniformName);
    
    CHECK_GL_ERRORS;

#if defined(DEBUG)
    if (result == -1) {
        std::stringstream errorMessage;
        errorMessage << "Error obtaining uniform location: " << uniformName;
        std::cerr << errorMessage.str();
    }
#endif

    return result;
}


//------------------------------------------------------------------------------------
GLint ShaderProgram::getAttribLocation (
    const char * attributeName
) const {
    GLint result =
        glGetAttribLocation(impl->programObject, (const GLchar *)attributeName);
    
    CHECK_GL_ERRORS;

#if defined(DEBUG)
    if (result == -1) {
        stringstream errorMessage;
        errorMessage << "Error obtaining attribute location: " << attributeName;
        std::cerr << errorMessage.str();
    }
#endif

    return result;
}


//------------------------------------------------------------------------------------
ShaderProgram::operator GLuint () const
{
    return impl->programObject;
}