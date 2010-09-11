//
//  ShaderProgram.h
//  ES2Framework
//
//  Created by Ryan Evans on 9/8/10.
//  Copyright 2010 Muteki Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>

@interface ShaderProgram : NSObject {
@protected
    GLuint m_programID;
    GLuint m_vertShaderID;
    GLuint m_fragShaderID;
    NSMutableDictionary* m_attributeMap;
}

@property GLuint programID;

+ (void)enableDebugging:(BOOL)a_shouldDebug;
+ (ShaderProgram*)programWithVertexShader:(NSString*)a_vertShader andFragmentShader:(NSString*)a_fragmentShader;
+ (void)deleteAllPrograms;

- (void)setAsActive;
- (GLint)indexForAttribute:(NSString*)a_attributeName;

@end
