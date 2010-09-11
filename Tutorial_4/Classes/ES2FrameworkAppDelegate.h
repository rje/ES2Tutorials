//
//  ES2FrameworkAppDelegate.h
//  ES2Framework
//
//  Created by Ryan Evans on 9/4/10.
//  All code in this file is licensed under the MIT license.
//

#import <UIKit/UIKit.h>

@class ES2FrameworkViewController;

@interface ES2FrameworkAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ES2FrameworkViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ES2FrameworkViewController *viewController;

@end

