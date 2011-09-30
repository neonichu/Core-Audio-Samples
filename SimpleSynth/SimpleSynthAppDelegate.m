//
//  SimpleSynthAppDelegate.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NNKeyboardVC.h"
#import "SimpleSynthAppDelegate.h"

@implementation SimpleSynthAppDelegate

@synthesize synthController;
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window makeKeyAndVisible];
    
    NNKeyboardVC* keyboardVC = [[NNKeyboardVC alloc] init];
    self.window.rootViewController = keyboardVC;
    self.window.rootViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
    self.window.rootViewController.view.backgroundColor = [UIColor blackColor];
    
    self.synthController = [[SynthController alloc] init];
    
    keyboardVC.keyboard = self.synthController.keyboard;
    keyboardVC.synthController = self.synthController;
    self.synthController.levelMeter.delegate = keyboardVC.levelMeter;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.synthController.session stop];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (self.synthController.session) {
        [self.synthController.session start];
    }
}

@end