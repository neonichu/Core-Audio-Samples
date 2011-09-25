//
//  SynthController.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "SynthController.h"

#import "NANode+Debug.h"

@implementation SynthController

@synthesize keyboard;
@synthesize session;

- (id)init
{
    self = [super init];
    if (self) {
        self.session = [[NASession alloc] init];
        
        self.keyboard = [[NNKeyboard alloc] initWithSampleRate:self.session.graphSampleRate];
        [session addNode:self.keyboard];
        
        NARemoteIO* output = [[NARemoteIO alloc] init];
        [self.session addNode:output];
        
        [self.session connectSourceNode:self.keyboard busNumber:0 toTargetNode:output busNumber:0];
        [self.session start];
    }
    return self;
}

@end