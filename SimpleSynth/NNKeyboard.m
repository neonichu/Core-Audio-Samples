//
//  NNKeyboard.m
//  SimpleSynth
//
//  Created by Boris Bügling on 25.09.11.
//  Copyright (c) 2011 - All rights reserved.
//

#import "NNKeyboard.h"

#define NOTE_START          72
#define NOTE_END            83

typedef enum {
    NNPlayState_On,
    NNPlayState_Off,
} NNPlayState;

#pragma mark -

@interface NNKeyboard ()

@property (nonatomic, readonly) NNPlayState* playState;

@end

#pragma mark -

static OSStatus inputRenderCallback (
									 void                        *inRefCon,
									 AudioUnitRenderActionFlags  *ioActionFlags,
									 const AudioTimeStamp        *inTimeStamp,
									 UInt32                      inBusNumber,
									 UInt32                      inNumberFrames,
									 AudioBufferList             *ioData
									 ) {
    na_clearLiveBuffer(inNumberFrames, ioData);
    
	NNKeyboard* mixer = (__bridge NNKeyboard*)inRefCon;
    
    switch (mixer.playState[inBusNumber]) {
        case NNPlayState_On:
            if (na_copySamplesToLiveBuffer(mixer, inBusNumber, inNumberFrames, ioData, NO)) {
                mixer.playState[inBusNumber] = NNPlayState_Off;
            }
            break;
        default:
            break;
    }
    
    return noErr;
}

#pragma mark -

@implementation NNKeyboard

@synthesize playState;

-(id)initWithSampleRate:(Float64)rate {
    self = [super initWithSampleRate:rate];
    if (self) {
        self.attachCallbacks = NO;
        self.numberOfBuses = 12;
        
        playState = (NNPlayState*)malloc(self.numberOfBuses * sizeof(NNPlayState));
        for (int i = 0; i < self.numberOfBuses; i++) {
            self.playState[i] = NNPlayState_Off;
        }
        
        for (int midiNote = NOTE_START; midiNote <= NOTE_END; midiNote++) {
            NSURL* fileURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"FluidR3_GM-%i", midiNote]
                                                     withExtension:@"caf"];
            [self readAudioFile:fileURL busIndex:midiNote - NOTE_START];
        }
    }
    return self;
}

-(void)dealloc {
    if (playState) free(playState);
}

-(void)initializeUnitForGraph:(AUGraph)graph {
	[super initializeUnitForGraph:graph];
	
	for (UInt16 busNumber = 0; busNumber < self.numberOfBuses; ++busNumber) {
        [self attachInputCallback:&inputRenderCallback toBus:busNumber inGraph:graph];
	}
}

-(void)pressKey:(NNKey)key {
    int note = -1;
    switch (key) {
        case NNKey_C: note = 0; break;
        case NNKey_CHash: note = 1; break;
        case NNKey_D: note = 2; break;
        case NNkey_DHash: note = 3; break;
        case NNKey_E: note = 4; break;
        case NNKey_F: note = 5; break;
        case NNKey_FHash: note = 6; break;
        case NNKey_G: note = 7; break;
        case NNKey_GHash: note = 8; break;
        case NNKey_A: note = 9; break;
        case NNKey_AHash: note = 10; break;
        case NNKey_B: note = 11; break;
    }
    
    if (note > -1 && note < self.numberOfBuses) {
        self.playState[note] = NNPlayState_On;
        [self setSampleNumber:0 forBusIndex:note];
    }
}

@end