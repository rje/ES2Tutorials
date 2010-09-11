//
//  ShaderProgram.m
//  ES2Framework
//
//  Created by Ryan Evans on 9/8/10.
//  Copyright 2010 Muteki Corporation. All rights reserved.
//

#import "ShaderProgram.h"

@interface ShaderProgram(secret)
- (BOOL)compileShader:(NSString*)a_file withType:(GLenum)a_type;
- (BOOL)linkProgram;
- (BOOL)loadAttributeMap;
+ (ShaderProgram*)findProgramWithKey:(NSString*)a_key;
+ (GLint)findShaderWithName:(NSString*)a_name andType:(GLenum)a_type;
@end

@implementation ShaderProgram

@synthesize programID = m_programID;

/* Static dictionaries that we use to cache precompiled shader data */
static NSMutableDictionary* sm_programCache = nil;
static NSMutableDictionary* sm_vertexShaderCache = nil;
static NSMutableDictionary* sm_fragmentShaderCache = nil;

/* Whether or not we'll do extra error checking and debug messaging */
static BOOL sm_showDebugging = NO;

- (ShaderProgram*)init {
    if(self = [super init]) {
        m_programID = glCreateProgram();
        m_vertShaderID = 0;
        m_fragShaderID = 0;
        m_attributeMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (void)enableDebugging:(BOOL)a_shouldDebug {
    sm_showDebugging = a_shouldDebug;
}
+ (ShaderProgram*)programWithVertexShader:(NSString*)a_vertShader andFragmentShader:(NSString*)a_fragmentShader {
    NSString* cacheKey = [NSString stringWithFormat:@"%@-%@", a_vertShader, a_fragmentShader];
    ShaderProgram* toReturn = [self findProgramWithKey:cacheKey];
    if(toReturn == nil) {
        if(sm_showDebugging) {
            NSLog(@"No program found with shaders (v: %@, f: %@), creating a new one", a_vertShader, a_fragmentShader);
        }
        toReturn = [[ShaderProgram alloc] init];
        BOOL result = [toReturn compileShader:a_vertShader withType:GL_VERTEX_SHADER];
        result = [toReturn compileShader:a_fragmentShader withType:GL_FRAGMENT_SHADER];
        result = [toReturn linkProgram];
        result = [toReturn loadAttributeMap];
        [sm_programCache setObject:toReturn forKey:cacheKey];
    }
    
    return toReturn;
}

+ (void)deleteAllPrograms {
    for(NSString* key in [sm_programCache keyEnumerator]) {
        ShaderProgram* toDelete = [sm_programCache objectForKey:key];
        glDeleteProgram(toDelete.programID);
    }
    [sm_programCache removeAllObjects];
    
    for(NSString* key in [sm_vertexShaderCache keyEnumerator]) {
        GLint shaderID = [[sm_vertexShaderCache objectForKey:key] intValue];
        glDeleteShader(shaderID);
    }
    [sm_vertexShaderCache removeAllObjects];
    
    for(NSString* key in [sm_fragmentShaderCache keyEnumerator]) {
        GLint shaderID = [[sm_fragmentShaderCache objectForKey:key] intValue];
        glDeleteShader(shaderID);
    }
    [sm_fragmentShaderCache removeAllObjects];
}

- (GLint)indexForAttribute:(NSString*)a_attributeName {
    NSNumber* result = [m_attributeMap objectForKey:a_attributeName];
    if(result) {
        return [result intValue];
    }
    else {
        return -1;
    }
}

+ (ShaderProgram*)findProgramWithKey:(NSString*)a_key {
    if(sm_programCache == nil) {
        sm_programCache = [[NSMutableDictionary alloc] initWithCapacity:10];
        [sm_programCache retain];
    }
    return [sm_programCache objectForKey:a_key];
}

+ (GLint)findShaderWithName:(NSString*)a_name andType:(GLenum)a_type {
    NSNumber* result = nil;
    switch (a_type) {
        case GL_VERTEX_SHADER:
            if(sm_vertexShaderCache == nil) {
                sm_vertexShaderCache = [[NSMutableDictionary alloc] initWithCapacity:10];
                [sm_vertexShaderCache retain];
            }
            result = [sm_vertexShaderCache objectForKey:a_name];
            break;
        case GL_FRAGMENT_SHADER:
            if(sm_fragmentShaderCache == nil) {
                sm_fragmentShaderCache = [[NSMutableDictionary alloc] initWithCapacity:10];
                [sm_fragmentShaderCache retain];
            }
            result = [sm_fragmentShaderCache objectForKey:a_name];
            break;
    }
    if(result) {
        return [result intValue];
    }
    else {
        return -1;
    }
}

- (BOOL)compileShader:(NSString*)a_file withType:(GLenum)a_type {
    GLint shaderID = [ShaderProgram findShaderWithName:a_file andType:a_type];
    if(shaderID == -1) {
        if(sm_showDebugging) {
            NSLog(@"No cached value found for shader %@, compiling...", a_file);
        }
        shaderID = glCreateShader(a_type);
        NSString* baseName = [a_file stringByDeletingPathExtension];
        NSString* extension = [a_file pathExtension];
        NSString* fullPath = [[NSBundle mainBundle] pathForResource:baseName ofType:extension];
        NSError* error;
        NSString* sourceString = [NSString stringWithContentsOfFile: fullPath
                                                           encoding: NSASCIIStringEncoding
                                                              error: &error];
        const GLchar* sourceData = (GLchar*)[sourceString cStringUsingEncoding:NSASCIIStringEncoding];
        glShaderSource(shaderID, 1, &sourceData, NULL);
        glCompileShader(shaderID);
        
        GLint compiled;
        glGetShaderiv(shaderID, GL_COMPILE_STATUS, &compiled);
        
        if(!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, &infoLen);
            if(infoLen > 1) {
                char* infoLog = malloc(infoLen * sizeof(char));
                glGetShaderInfoLog(shaderID, infoLen, NULL, infoLog);
                NSLog(@"****ERROR COMPILING SHADER(%@):\n\t%s", a_file, infoLog);
                free(infoLog);
            }
            glDeleteShader(shaderID);
            return NO;
        }
        
        switch (a_type) {
            case GL_VERTEX_SHADER:
                [sm_vertexShaderCache setObject:[NSNumber numberWithInt:shaderID] forKey:a_file];
                break;
            case GL_FRAGMENT_SHADER:
                [sm_fragmentShaderCache setObject:[NSNumber numberWithInt:shaderID] forKey:a_file];
                break;
        }
    }
    else {
        if(sm_showDebugging) {
            NSLog(@"Returning cached result for shader %@", a_file);
        }
    }
    switch (a_type) {
        case GL_VERTEX_SHADER:
            m_vertShaderID = shaderID;
            break;
        case GL_FRAGMENT_SHADER:
            m_fragShaderID = shaderID;
            break;
    }
    return YES;
}

- (BOOL)linkProgram {
    glAttachShader(m_programID, m_vertShaderID);
    glAttachShader(m_programID, m_fragShaderID);
    glLinkProgram(m_programID);
    
    GLint linked;
	glGetProgramiv(m_programID, GL_LINK_STATUS, &linked);
	if(!linked) {
		GLint infoLen = 0;
		glGetProgramiv(m_programID, GL_INFO_LOG_LENGTH, &infoLen);
		if(infoLen > 1) {
			char* infoLog = malloc(infoLen * sizeof(char));
			glGetProgramInfoLog(m_programID, infoLen, NULL, infoLog);
			NSLog(@"****ERROR LINKING SHADER PROGRAM:\n\t%s", infoLog);
			free(infoLog);
            return NO;
		}
	}
    if(sm_showDebugging) {
        NSLog(@"Shader Program linked");
    }
    return YES;
}

- (BOOL)loadAttributeMap {
    GLint numToRead = 0;
    glGetProgramiv(m_programID, GL_ACTIVE_ATTRIBUTES, &numToRead);
    char nameBuf[255];
    GLsizei len;
    GLint size;
    GLenum type;
    for(int i = 0; i < numToRead; i++) {
        bzero(nameBuf, sizeof(char) * 255);
        glGetActiveAttrib(m_programID, i, 255, &len, &size, &type, nameBuf);
        GLint loc = glGetAttribLocation(m_programID, nameBuf);
        NSString* attribName = [NSString stringWithCString:nameBuf encoding:NSASCIIStringEncoding];
        if(sm_showDebugging) {
            NSLog(@"\tAttribute \"%@\" using index: %d", attribName, loc);
        }
        [m_attributeMap setObject:[NSNumber numberWithInt:loc] forKey:attribName];
    }
    return YES;
}

- (void)setAsActive {
    glUseProgram(m_programID);
}

@end
