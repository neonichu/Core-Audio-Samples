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
@synthesize levelMeter;
@synthesize midiHandler;
@synthesize reverbEffect;
@synthesize session;
@synthesize sineWave;

- (void)midiNotePlayed:(NSNotification*)notification
{
    int notePlayed = [[notification.userInfo objectForKey:kNAMIDI_NoteKey] intValue] % 12;
    
    if (self.reverbEffect.inputNode == self.keyboard) {
        [self.keyboard pressKey:notePlayed];
    } else {
        self.sineWave.frequency = (notePlayed + 4) * 100;
        [self.sineWave play];
    }
}

-(void)switchSynthInputNodeToNode:(NANode*)node
{
    [self.session stop];
    self.reverbEffect.inputNode = node;
    [self.session start];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.session = [[NASession alloc] init];
        
        self.keyboard = [[NNKeyboard alloc] initWithSampleRate:self.session.graphSampleRate];
        [session addNode:self.keyboard];
        
        self.sineWave = [[NASineWave alloc] init];
        [session addNode:self.sineWave];
        
        self.reverbEffect = [[NAReverbEffect alloc] init];
        [session addNode:self.reverbEffect];
        
        NARemoteIO* output = [[NARemoteIO alloc] init];
        [self.session addNode:output];
        
        self.reverbEffect.inputNode = self.keyboard;
        [self.session connectSourceNode:self.reverbEffect busNumber:0 toTargetNode:output busNumber:0];
        [self.session start];
        
        self.levelMeter = [[NALevelMeter alloc] init];
        [output attachRenderNotifier:self.levelMeter.renderCallback withUserData:(__bridge void*)self.levelMeter];
        
        self.midiHandler = [[NAMIDI alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(midiNotePlayed:) name:kNAMIDINoteOnNotification 
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end