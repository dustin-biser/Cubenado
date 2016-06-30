//
//  GLUtils.h
//

#import <OpenGLES/ES3/gl.h>


@interface GLUtils : NSObject

+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)shaderType file:(NSString *)file;

+ (BOOL)linkProgram:(GLuint)prog;

+ (BOOL)validateProgram:(GLuint)prog;

@end
