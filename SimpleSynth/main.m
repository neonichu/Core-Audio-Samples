//
//  main.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SimpleSynthAppDelegate.h"

int main(int argc, char *argv[])
{
    int retVal = 0;
    @autoreleasepool {
        retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([SimpleSynthAppDelegate class]));
    }
    return retVal;
}