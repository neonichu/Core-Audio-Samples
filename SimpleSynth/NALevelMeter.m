//
//  NALevelMeter.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//
//  Source: http://www.politepix.com/2010/06/18/decibel-metering-from-an-iphone-audio-unit/
//

#import "NALevelMeter.h"

#define DBOFFSET				-74.0
#define LOWPASSFILTERTIMESLICE	0.001

static OSStatus LevelMeterRenderCallback (void *inRefCon,
										  AudioUnitRenderActionFlags *ioActionFlags,
										  const AudioTimeStamp *inTimeStamp,
										  UInt32 inBusNumber,
										  UInt32 inNumberFrames,
										  AudioBufferList *ioData) 
{	
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
		static int TEMP_kAudioUnitRenderAction_PostRenderError = (1 << 8);
		if (!(*ioActionFlags & TEMP_kAudioUnitRenderAction_PostRenderError)) {
			NALevelMeter* levelMeter = (__bridge NALevelMeter*)inRefCon;
			
			for (int buf = 0; buf < ioData->mNumberBuffers; buf++) {
				SInt16* samples = (SInt16*)(ioData->mBuffers[buf].mData);
				
				levelMeter->peakPowers[buf] = DBOFFSET;
				
				Float32 currentFilteredValueOfSampleAmplitude, previousFilteredValueOfSampleAmplitude = 0.0;
				Float32 peakValue = DBOFFSET;
				
				for (int i = 0; i < inNumberFrames; i++) { 
					Float32 absoluteValueOfSampleAmplitude = abs(samples[i]);
					
					currentFilteredValueOfSampleAmplitude = LOWPASSFILTERTIMESLICE * 
                    absoluteValueOfSampleAmplitude +  
                    (1.0 - LOWPASSFILTERTIMESLICE) * 
                    previousFilteredValueOfSampleAmplitude;
					
					previousFilteredValueOfSampleAmplitude = currentFilteredValueOfSampleAmplitude;
					
					Float32 amplitudeToConvertToDB = currentFilteredValueOfSampleAmplitude;
					Float32 sampleDB = 20.0*log10(amplitudeToConvertToDB) + DBOFFSET;
					
					if ((sampleDB == sampleDB) && (sampleDB <= DBL_MAX && sampleDB >= -DBL_MAX)) {
						if (sampleDB > peakValue) {
							peakValue = sampleDB;
						}
						levelMeter->peakPowers[buf] = peakValue;
					}
				}
				
				if (levelMeter.delegate) {
					[levelMeter.delegate peakPowerChangedTo:levelMeter->peakPowers[buf]];
				}
			}
		}
	}
	
	return noErr;
}

@implementation NALevelMeter

@synthesize delegate;
@synthesize renderCallback;

- (id)init 
{
	self = [super init];
	if (self) {
		renderCallback = LevelMeterRenderCallback;
	}
	return self;
}

- (void)dealloc 
{
	delegate = nil;
}

- (float)peakPowerForChannel:(NSInteger)channelNumber 
{
	if (channelNumber < 0 || channelNumber > 2) {
		return DBOFFSET;
	}
	return peakPowers[channelNumber];
}

@end