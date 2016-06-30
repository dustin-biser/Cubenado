//
//  GLCheckErrors.h
//

#pragma once

#import "GLUtils.h"


#if defined(DEBUG)
#define CHECK_GL_ERRORS checkGLErrors(__FILE__, __LINE__)
#else
#define CHECK_GL_ERRORS
#endif

#if defined(DEBUG)
#define VALIDATE_GL_PROGRAM(prog) [GLUtils validateProgram:(prog)]
#else
#define VALIDATE_GL_PROGRAM(prog)
#endif

void checkGLErrors(const char * currentFileName, int currentLineNumber);


