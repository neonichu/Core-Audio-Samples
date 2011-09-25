//
//  NAMixer.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

#import "NANode.h"

@class NAMixer;

void na_clearLiveBuffer(UInt32 inNumberFrames, AudioBufferList* ioData);
BOOL na_copySamplesToLiveBuffer(NAMixer* mixer, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData, BOOL shouldLoop);

@interface NAMixer : NANode

@property (nonatomic, assign) BOOL attachCallbacks;
@property (nonatomic, readwrite) NSUInteger numberOfBuses;

-(id)initWithSampleRate:(Float64)rate;

-(BOOL)readAudioFile:(NSURL*)fileUrl busIndex:(UInt32)audioFile;
-(void)setSampleNumber:(UInt32)sampleNumber forBusIndex:(UInt32)busIndex;

-(void)enableMixerInput:(UInt32)inputBus isOn:(AudioUnitParameterValue)isOnValue;
-(void)setMixerInput:(UInt32)inputBus gain:(AudioUnitParameterValue)newGain;

@end