//
// Prefix header for all source files project
//

#ifdef __OBJC__
    #import <UIKit/UIKit.h>
    #import <Foundation/Foundation.h>

    #import <OpenGLES/EAGL.h>
    #import <OpenGLES/ES3/gl.h>
    #import <OpenGLES/ES3/glext.h>
    #import <QuartzCore/QuartzCore.h>

    #import "GLCheckErrors.h"
    #import "NumericTypes.h"
#endif

#ifdef __cplusplus
    #import <OpenGLES/ES3/gl.h>
    #import <OpenGLES/ES3/glext.h>

    #import "GLCheckErrors.h"
    #import "NumericTypes.h"
#endif