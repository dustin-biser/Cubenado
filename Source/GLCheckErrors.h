//
//  GLCheckErrors.h
//

#pragma once


#if defined(DEBUG)
#define CHECK_GL_ERRORS checkGLErrors(__FILE__, __LINE__)
#else
#define CHECK_GL_ERRORS
#endif

#if defined(DEBUG)
#define CHECK_FRAMEBUFFER_COMPLETENESS checkFramebufferCompleteness()
#else
#define CHECK_FRAMEBUFFER_COMPLETENESS
#endif

void checkGLErrors(const char * currentFileName, int currentLineNumber);

void checkFramebufferCompleteness();

