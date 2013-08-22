//
//  AppDelegate.m
//  ESMediaPlayer
//
//  Created by Elf Sundae on 8/16/13.
//  Copyright (c) 2013 www.0x123.com. All rights reserved.
//

#import "AppDelegate.h"
#import "InputViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window.backgroundColor = [UIColor whiteColor];
        [self.window makeKeyAndVisible];
        
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:
                                          [InputViewController new]];
        
        return YES;
}


@end
