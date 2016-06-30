//
//  GLCheckErrors.h
//

#pragma once


#if defined(DEBUG)
#define CHECK_GL_ERRORS checkGLErrors(__FILE__, __LINE__)
#else
#define CHECK_GL_ERRORS
#endif

void checkGLErrors(const char * currentFileName, int currentLineNumber);


