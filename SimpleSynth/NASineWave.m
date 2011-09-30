//
//  NASineWave.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//
//  Source: http://code.google.com/p/mobilesynth/
//

#import "NASineWave.h"

#include <mach/mach_time.h>

#define kFadeInDuration         200
#define kFadeOutDuration		200

typedef enum {
	NAToneState_Attack,
	NAToneState_Off,
	NAToneState_Release,
	NAToneState_Sustain
} NAToneState;

@interface NASineWave ()

@property (nonatomic, assign) int fadeCounter;
@property (nonatomic, assign) long sampleNum;
@property (nonatomic, assign) Float64 sampleRate;
@property (nonatomic, assign) NAToneState state;

@end

#pragma mark -

static float generate_audio(NASineWave* generator) {
	Float64 freq = generator.frequency;
	if (freq < 0.01f) {
		return 0.0f;
	}
	
	long period_samples = generator.sampleRate / freq;
	if (period_samples == 0) {
		return 0.0f;
	}
	
	long sampleNum = generator.sampleNum;
	float x = (sampleNum / (float)period_samples);
	
	float value = sinf(2.0f * M_PI * x);
	
	generator.sampleNum = (sampleNum + 1) % period_samples;
	
	float fadeMultiplier = 1.0f;
	switch (generator.state) {
		case NAToneState_Attack:
			fadeMultiplier = (float)generator.fadeCounter / kFadeInDuration;
			generator.fadeCounter++;
            if (generator.fadeCounter >= kFadeInDuration) generator.state = NAToneState_Sustain;
			break;
        case NAToneState_Off:
            fadeMultiplier = 0.0f;
            break;
		case NAToneState_Release:
			fadeMultiplier = 1.0f - (float)generator.fadeCounter / kFadeOutDuration;
			generator.fadeCounter++;
            if (generator.fadeCounter >= kFadeOutDuration) generator.state = NAToneState_Off;
			break;
        case NAToneState_Sustain:
            fadeMultiplier = 1.0f;
            break;
	}
	value *= fadeMultiplier;
	
	return value;
}

static OSStatus RenderTone(
					void *inRefCon, 
					AudioUnitRenderActionFlags 	*ioActionFlags, 
					const AudioTimeStamp 		*inTimeStamp, 
					UInt32 						inBusNumber, 
					UInt32 						inNumberFrames, 
					AudioBufferList 			*ioData)

{	
    NASineWave* generator = (__bridge NASineWave*)inRefCon;
    
    // Compute time since device launch in nanoseconds
	mach_timebase_info_data_t tinfo;
	mach_timebase_info(&tinfo);
	double hTime2nsFactor = (double)tinfo.numer / tinfo.denom;
	double nanoseconds = inTimeStamp->mHostTime * hTime2nsFactor;
	
    // Just get the fraction of the second
	double seconds = (nanoseconds) / 1000000000.0;
	seconds -= floor(seconds);
	
	// Handle fade-in and -out
    if (generator.state != NAToneState_Off) {
        if (seconds < 0.2) {
            generator.fadeCounter = 0;
            generator.state = NAToneState_Attack;
        }
        if (seconds > 0.8) {
            generator.fadeCounter = 0;
            generator.state = NAToneState_Release;
        }
    }
    
    for (int buffer = 0; buffer < ioData->mNumberBuffers; buffer++) {
        AudioUnitSampleType* audio = (AudioUnitSampleType*)ioData->mBuffers[buffer].mData;
        for (int frame = 0; frame < inNumberFrames; frame++) {
            float sample = generate_audio(generator);
            audio[frame] = sample * 16777216L;
        }
    }
	
	return noErr;
}

#pragma mark -

@implementation NASineWave

@synthesize fadeCounter;
@synthesize frequency;
@synthesize sampleNum;
@synthesize sampleRate;
@synthesize state;

-(void)initializeUnitForGraph:(AUGraph)graph {
	[super initializeUnitForGraph:graph];
	
	self.sampleRate = [self outputSampleRate];
	
	[self attachInputCallback:RenderTone toBus:0 inGraph:graph];
}

-(id)init {
	self = [super initWithComponentType:kAudioUnitType_Effect andComponentSubType:kAudioUnitSubType_AUiPodEQ];
    if (self) {
        self.state = NAToneState_Off;
    }
	return self;
}

-(void)play {
    self.sampleNum = 0;
    self.state = NAToneState_Attack;
}

@end