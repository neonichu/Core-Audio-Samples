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

@interface NASineWave ()

@property (nonatomic, assign) BOOL on;
@property (nonatomic, assign) long sampleNum;
@property (nonatomic, assign) Float64 sampleRate;

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
	
	float x = (generator.sampleNum / (float)period_samples);
	float value = sinf(2.0f * M_PI * x);
	generator.sampleNum = (generator.sampleNum + 1) % period_samples;
	
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
    
    for (int buffer = 0; buffer < ioData->mNumberBuffers; buffer++) {
        memset(ioData->mBuffers[buffer].mData, 0, inNumberFrames * sizeof(AudioUnitSampleType));
    }
    
    if (!generator.on) {
        return noErr;
    }
    
	mach_timebase_info_data_t tinfo;
	mach_timebase_info(&tinfo);
	double hTime2nsFactor = (double)tinfo.numer / tinfo.denom;
	double nanoseconds = inTimeStamp->mHostTime * hTime2nsFactor;
	
	double seconds = (nanoseconds) / 1000000000.0;
	seconds -= floor(seconds);
	
    if (seconds > 0.8) {
        generator.on = NO;
    }
    
    // mono, only fill one channel
    AudioUnitSampleType* audio = (AudioUnitSampleType*)ioData->mBuffers[0].mData;
    for (int frame = 0; frame < inNumberFrames; frame++) {
        float sample = generate_audio(generator);
        audio[frame] = sample * 16777216L;
    }
	
	return noErr;
}

#pragma mark -

@implementation NASineWave

@synthesize frequency;
@synthesize on;
@synthesize sampleNum;
@synthesize sampleRate;

-(void)initializeUnitForGraph:(AUGraph)graph {
	[super initializeUnitForGraph:graph];
	
	self.sampleRate = [self outputSampleRate];
	
	[self attachInputCallback:RenderTone toBus:0 inGraph:graph];
}

-(id)init {
	self = [super initWithComponentType:kAudioUnitType_Effect andComponentSubType:kAudioUnitSubType_AUiPodEQ];
    if (self) {
        self.on = NO;
    }
	return self;
}

-(void)play {
    self.on = YES;
    self.sampleNum = 0;
}

@end