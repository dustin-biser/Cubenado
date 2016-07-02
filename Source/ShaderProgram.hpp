//
// ShaderProgram.hpp
//

#pragma once

#include <string>


// Forward declaration
class ShaderProgramImpl;


class ShaderProgram {
public:
    ShaderProgram();

    ~ShaderProgram();

    void generateProgramObject();

    void attachVertexShader(const std::string & filePath);
    
    void attachFragmentShader(const std::string & filePath);
    
    void link();

    void enable() const;

    void disable() const;

    GLuint programObject() const;
    
    GLint getUniformLocation(const char * uniformName) const;
    
    GLint getAttribLocation(const char * attributeName) const;
    
    // Support conversion to GLuint for use with GL functions.
    // Returns programObject.
    operator GLuint () const;
    
private:
    ShaderProgramImpl * impl;
};

