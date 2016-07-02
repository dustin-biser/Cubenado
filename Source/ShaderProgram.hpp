//
// ShaderProgram.hpp
//

#pragma once


// Forward Declaration
class ShaderProgramImpl;


class ShaderProgram {
public:
    ShaderProgram();

    ~ShaderProgram();

    void generateProgramObject();

    void attachVertexShader(const char * filePath);
    
    void attachFragmentShader(const char * filePath);
    
    void link();

    void enable() const;

    void disable() const;

    void recompileShaders();

    GLuint getProgramObject() const;
    
    GLint getUniformLocation(const char * uniformName) const;
    
    GLint getAttribLocation(const char * attributeName) const;
    
private:
    ShaderProgramImpl * impl;
};

