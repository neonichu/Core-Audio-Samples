//
//  SynthController.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NNAudio.h"
#import "NNKeyboard.h"

@interface SynthController : NSObject

@property (nonatomic, retain) NNKeyboard* keyboard;
@property (nonatomic, retain) NALevelMeter* levelMeter;
@property (nonatomic, retain) NAMIDI* midiHandler;
@property (nonatomic, retain) NASession* session;

@end