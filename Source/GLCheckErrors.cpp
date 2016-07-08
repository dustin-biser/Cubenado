//
//  GLCheckErrors.cpp
//
#import "GlCheckErrors.h"

#include <string>
using std::string;

#include <sstream>
using std::stringstream;

#include <iostream>
using std::cout;
using std::endl;


//---------------------------------------------------------------------------------------
const char * getErrorString (
    GLenum errorCode
) {
    const char * result;
    
    switch (errorCode) {
        case GL_NO_ERROR:
            break;
            
        case GL_INVALID_ENUM:
            result = "GL_INVALID_ENUM";
            break;
            
        case GL_INVALID_VALUE:
            result = "GL_INVALID_VALUE";
            break;
            
        case GL_INVALID_OPERATION:
            result = "GL_INVALID_OPERATION";
            break;
            
        case GL_OUT_OF_MEMORY:
            result = "GL_OUT_OF_MEMORY";
            break;
            
        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
            result = "GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT";
            break;
            
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            result = "GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";
            break;
            
        case GL_FRAMEBUFFER_UNSUPPORTED:
            result = "GL_FRAMEBUFFER_UNSUPPORTED";
            break;
            
        case GL_FRAMEBUFFER_UNDEFINED:
            result = "GL_FRAMEBUFFER_UNDEFINED";
            break;
            
        default:
            result = "UNKNOWN_ERROR";
            break;
    }
    
    return result;
}


//---------------------------------------------------------------------------------------
void checkGLErrors (
    const char * currentFileName,
    int currentLine
) {
    GLenum errorCode;
    bool errorFound = false;
    
    std::stringstream errorMessage;
    
    // Write all errors to errorMessage stringstream until error list is exhausted.
    do {
        errorCode = glGetError();
        
        if (errorCode != GL_NO_ERROR) {
            // Retrieve file name, disgarding full path
            std::string fileName(currentFileName);
            size_t pos = fileName.find_last_of("/");
            fileName = fileName.substr(pos+1);
            
            errorMessage << "GLError " << getErrorString(errorCode) << " "
            << "caused by " << fileName << ":" << currentLine << endl;
            
            errorFound = true;
        }
    } while (errorCode != GL_NO_ERROR);
    
    if (errorFound) {
        cout << errorMessage.str() << endl;
        throw;
    }
}


//---------------------------------------------------------------------------------------
void checkFramebufferCompleteness()
{
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        stringstream error;
        error << "Framebuffer Complete Error: ";
        error << getErrorString(status) << endl;;
        throw;
    }
}