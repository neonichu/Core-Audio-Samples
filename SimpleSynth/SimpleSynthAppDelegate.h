//
//  SimpleSynthAppDelegate.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SynthController.h"

@interface SimpleSynthAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) SynthController* synthController;
@property (strong, nonatomic) UIWindow *window;

@end