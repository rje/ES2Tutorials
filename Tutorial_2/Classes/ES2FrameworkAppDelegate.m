//
//  ES2FrameworkAppDelegate.m
//  ES2Framework
//
//  Created by Ryan Evans on 9/4/10.
//  All code in this file is licensed under the MIT license.
//

#import "ES2FrameworkAppDelegate.h"
#import "ES2FrameworkViewController.h"

@implementation ES2FrameworkAppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationWillResignActive:(UIApplication *)application
{
    [viewController stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [window addSubview:viewController.view];
    [viewController startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [viewController stopAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Handle any background procedures not related to animation here.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Handle any foreground procedures not related to animation here.
}

- (void)dealloc
{
    [viewController release];
    [window release];
    
    [super dealloc];
}

@end
