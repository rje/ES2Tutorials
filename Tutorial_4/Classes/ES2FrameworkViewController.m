//
//  ES2FrameworkViewController.m
//  ES2Framework
//
//  Created by Ryan Evans on 9/4/10.
//  All code in this file is licensed under the MIT license.
//

#import <QuartzCore/QuartzCore.h>

#import "ES2FrameworkViewController.h"
#import "EAGLView.h"
#import "ShaderProgram.h"

@interface ES2FrameworkViewController ()
@property (nonatomic, retain) EAGLContext *context;
@end

@implementation ES2FrameworkViewController

@synthesize animating, context;

- (void)awakeFromNib
{
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!aContext) {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    if (!aContext) {
        NSLog(@"Failed to create ES context");
    }
    else if (![EAGLContext setCurrentContext:aContext]) {
        NSLog(@"Failed to set ES context current");
    }
    
	self.context = aContext;
	[aContext release];
	
    [(EAGLView *)self.view setContext:context];
    [(EAGLView *)self.view setFramebuffer];
    
    if ([context API] == kEAGLRenderingAPIOpenGLES2) {
        [ShaderProgram enableDebugging:YES];
        [ShaderProgram programWithVertexShader:@"Shader.vsh" andFragmentShader:@"Shader.fsh"];
        [ShaderProgram programWithVertexShader:@"Shader.vsh" andFragmentShader:@"Grayscale.fsh"];
    }
    
    animating = FALSE;
    displayLinkSupported = FALSE;
    animationFrameInterval = 1;
    displayLink = nil;
    useGrayscale = NO;
    animationTimer = nil;
    
    // Use of CADisplayLink requires iOS version 3.1 or greater.
	// The NSTimer object is used as fallback when it isn't available.
    NSString *reqSysVer = @"3.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
        displayLinkSupported = TRUE;
    }
}

- (void)dealloc
{
    // Tear down context.
    if ([EAGLContext currentContext] == context) {
        [ShaderProgram deleteAllPrograms];
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];

    // Tear down context.
    if ([EAGLContext currentContext] == context) {
        [ShaderProgram deleteAllPrograms];
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;	
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        if (displayLinkSupported)
        {
            /*
			 CADisplayLink is API new in iOS 3.1. Compiling against earlier versions will result in a warning, but can be dismissed if the system version runtime check for CADisplayLink exists in -awakeFromNib. The runtime check ensures this code will not be called in system versions earlier than 3.1.
            */
            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawFrame)];
            [displayLink setFrameInterval:animationFrameInterval];
            
            // The run loop will retain the display link on add.
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawFrame) userInfo:nil repeats:TRUE];
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }
        
        animating = FALSE;
    }
}

- (void)drawFrame
{
    [(EAGLView *)self.view setFramebuffer];
    
    // Replace the implementation of this method to do your own custom drawing.
    static const GLfloat squareVertices[] = {
        -0.5f, 0.33f, 0.0f,
        0.5f, 0.33f, 0.0f,
        -0.5f, -0.33f, 0.0f,
        0.5f, -0.33f, 0.0f,
    };
    
    static const GLubyte squareColors[] = {
        255, 0, 0, 255,
        0, 255, 0, 255,
        0, 0, 255, 255,
        255, 255, 0, 255,
    };
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    switch([context API]) {
        case kEAGLRenderingAPIOpenGLES2: {
            // ES2 specific code
            ShaderProgram* p;
            if(useGrayscale) {
                p = [ShaderProgram programWithVertexShader:@"Shader.vsh" andFragmentShader:@"Grayscale.fsh"];
            }
            else {
                p = [ShaderProgram programWithVertexShader:@"Shader.vsh" andFragmentShader:@"Shader.fsh"];
            }
            [p setAsActive];
            GLint index = [p indexForAttribute:@"position"];
            glVertexAttribPointer(index, 3, GL_FLOAT, 0, 0, squareVertices);
            glEnableVertexAttribArray(index);
            index = [p indexForAttribute:@"color"];
            glVertexAttribPointer(index, 4, GL_UNSIGNED_BYTE, 1, 0, squareColors);
            glEnableVertexAttribArray(index);
            break;

        }
        case kEAGLRenderingAPIOpenGLES1: 
        default:
            // ES1 fallback
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            
            glVertexPointer(3, GL_FLOAT, 0, squareVertices);
            glEnableClientState(GL_VERTEX_ARRAY);
            glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors);
            glEnableClientState(GL_COLOR_ARRAY);
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [(EAGLView *)self.view presentFramebuffer];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // We're just using this to toggle a boolean
    useGrayscale = !useGrayscale;
}

@end
