//
//  NAMixer.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NADescription.h"
#import "NAMixer.h"
#import "NAUtils.h"

@interface NAMixer ()

@property (nonatomic, readonly) Float64 sampleRate;
@property (nonatomic, readonly) NASoundStruct* soundStructArray;

-(void)deallocAllSamples;
-(void)deallocSampleWithIndex:(NSUInteger)index;

@end

#pragma mark -

void na_clearLiveBuffer(UInt32 inNumberFrames, AudioBufferList* ioData) {
    for (int i = 0; i < ioData->mNumberBuffers; i++) {
        memset(ioData->mBuffers[i].mData, 0, inNumberFrames * sizeof(AudioUnitSampleType));
    }
}

BOOL na_copySamplesToLiveBuffer(NAMixer* mixer, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData, BOOL shouldLoop) {
    BOOL done = NO;
    NASoundStructPtr soundStructArray = mixer.soundStructArray;
	
	UInt32            frameTotalForSound        = soundStructArray[inBusNumber].frameCount;
    BOOL              isStereo                  = soundStructArray[inBusNumber].isStereo;

    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    
    dataInLeft                 = soundStructArray[inBusNumber].audioDataLeft;
    if (isStereo) dataInRight  = soundStructArray[inBusNumber].audioDataRight;
    
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
	
    // Get the sample number, as an index into the sound stored in memory, to start reading data from.
    UInt32 sampleNumber = soundStructArray[inBusNumber].sampleNumber;
	
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
		
		if (dataInLeft) outSamplesChannelLeft[frameNumber]                = dataInLeft[sampleNumber];
        if (isStereo && dataInRight) outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        
        sampleNumber++;
		
        // After reaching the end of the sound stored in memory--that is, after
        //    (frameTotalForSound / inNumberFrames) invocations of this callback--loop back to the 
        //    start of the sound so playback resumes from there.
        if (sampleNumber >= frameTotalForSound) {
            done = YES;
            sampleNumber = 0;
            if (!shouldLoop) break;
        }
    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes at the correct spot.
    soundStructArray[inBusNumber].sampleNumber = sampleNumber;
    
    return done;
}

#pragma mark -
#pragma mark Mixer input bus render callback

//    This callback is invoked each time a Multichannel Mixer unit input bus requires more audio
//        samples. In this app, the mixer unit has two input buses. Each of them has its own render 
//        callback function and its own interleaved audio data buffer to read from.
//
//    This callback is written for an inRefCon parameter that can point to two noninterleaved 
//        buffers (for a stereo sound) or to one mono buffer (for a mono sound).
//
//    Audio unit input render callbacks are invoked on a realtime priority thread (the highest 
//    priority on the system). To work well, to not make the system unresponsive, and to avoid 
//    audio artifacts, a render callback must not:
//
//        * allocate memory
//        * access the file system or a network connection
//        * take locks
//        * waste time
//
//    In addition, it's usually best to avoid sending Objective-C messages in a render callback.
//
//    Declared as AURenderCallback in AudioUnit/AUComponent.h. See Audio Unit Component Services Reference.
static OSStatus inputRenderCallback (
									 void                        *inRefCon,
									 AudioUnitRenderActionFlags  *ioActionFlags,
									 const AudioTimeStamp        *inTimeStamp,
									 UInt32                      inBusNumber,
									 UInt32                      inNumberFrames,
									 AudioBufferList             *ioData
									 ) {
	NAMixer* mixer = (__bridge NAMixer*)inRefCon;
	na_copySamplesToLiveBuffer(mixer, inBusNumber, inNumberFrames, ioData, YES);
    return noErr;
}

#pragma mark -

@implementation NAMixer

@synthesize attachCallbacks;
@synthesize numberOfBuses;
@synthesize sampleRate;
@synthesize soundStructArray;

#pragma mark -

-(void)initializeUnitForGraph:(AUGraph)graph {
	[super initializeUnitForGraph:graph];
	
    OSStatus result = AudioUnitSetProperty (
											self.unit,
											kAudioUnitProperty_ElementCount,
											kAudioUnitScope_Input,
											0,
											&numberOfBuses,
											sizeof (numberOfBuses)
											);
    if ([NAUtils printErrorMessage:@"AudioUnitSetProperty (set mixer unit bus count)" withStatus:result]) return;
	
	// Increase the maximum frames per slice allows the mixer unit to accommodate the larger slice size used when the screen is locked.
    [self setMaximumFramesPerSlice:4096];
	
	for (UInt16 busNumber = 0; busNumber < numberOfBuses; ++busNumber) {
		if (soundStructArray[busNumber].frameCount == 0) {
			continue;
		}
		
		if (soundStructArray[busNumber].isStereo) {
			[self setInputFormat:[NADescription basicDescriptionForType:NADescriptionTypeStereo sampleRate:self.sampleRate] 
                          forBus:busNumber];
		} else {
			[self setInputFormat:[NADescription basicDescriptionForType:NADescriptionTypeMono sampleRate:self.sampleRate] 
                          forBus:busNumber];
		}
        
        if (self.attachCallbacks) {
            [self attachInputCallback:&inputRenderCallback toBus:busNumber inGraph:graph];
        }
	}
}

#pragma mark -
#pragma mark Handle buses

-(BOOL)readAudioFile:(NSURL*)fileUrl busIndex:(UInt32)audioFile {
	if (audioFile >= numberOfBuses) {
		NSLog(@"Bus index %li out of range %d", audioFile, numberOfBuses);
		return NO;
	}
    
	[self deallocSampleWithIndex:audioFile];
    
	[NAUtils readAudioFile:fileUrl sampleRate:self.sampleRate intoSoundStruct:&self.soundStructArray[audioFile]];
    
	return YES;
}

-(void)setNumberOfBuses:(NSUInteger)buses {
	if (numberOfBuses != -1) {
		return;
	}
	
	numberOfBuses = buses;
	
	if (buses > 0) {
		soundStructArray = (NASoundStruct*)malloc(buses * sizeof(NASoundStruct));
		memset(soundStructArray, 0, buses * sizeof(NASoundStruct));
	}
}


-(void)setSampleNumber:(UInt32)sampleNumber forBusIndex:(UInt32)busIndex {
    if (busIndex >= numberOfBuses) {
		NSLog(@"Bus index %li out of range %d", busIndex, numberOfBuses);
		return;
	}
    
    self.soundStructArray[busIndex].sampleNumber = sampleNumber;
}

#pragma mark -
#pragma mark Mixer unit control

-(void)enableMixerInput:(UInt32)inputBus isOn:(AudioUnitParameterValue)isOnValue {
	self.soundStructArray[inputBus].isActive = isOnValue;
	
	OSStatus result = AudioUnitSetParameter (
											 self.unit,
											 kMultiChannelMixerParam_Enable,
											 kAudioUnitScope_Input,
											 inputBus,
											 self.soundStructArray[inputBus].isActive,
											 0
											 );
	[NAUtils printErrorMessage: @"AudioUnitSetParameter (enable the mixer unit)" withStatus: result];
    
	if (isOnValue > 0) {
		UInt32 currentSampleNumber = -1;
		for (int i = 0; i < self.numberOfBuses; i++) {
			if (self.soundStructArray[i].isActive && self.soundStructArray[i].frameCount > 0) {
				currentSampleNumber = self.soundStructArray[i].sampleNumber;
			}
		}
		
		if (currentSampleNumber != -1) {
			self.soundStructArray[inputBus].sampleNumber = currentSampleNumber;
		}
	}
}

#pragma mark -
#pragma mark Volume controls

// Set the mixer unit input volume for a specified bus
-(void)setMixerInput:(UInt32)inputBus gain:(AudioUnitParameterValue)newGain {
	if (newGain == 0) {
		newGain = 0.01;
	}
	
    OSStatus result = AudioUnitSetParameter (
											 self.unit,
											 kMultiChannelMixerParam_Volume,
											 kAudioUnitScope_Input,
											 inputBus,
											 newGain,
											 0
											 );
	
    if ([NAUtils printErrorMessage:@"AudioUnitSetParameter (set mixer unit input volume)" withStatus:result]) return;
}

// Set the mxer unit output volume
-(void)setMixerOutputGain:(AudioUnitParameterValue)newGain {
    OSStatus result = AudioUnitSetParameter (
											 self.unit,
											 kMultiChannelMixerParam_Volume,
											 kAudioUnitScope_Output,
											 0,
											 newGain,
											 0
											 );
	
    if ([NAUtils printErrorMessage:@"AudioUnitSetParameter (set mixer unit output volume)" withStatus:result]) return;
}

#pragma mark -
#pragma mark Initialize

-(id)init {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

-(id)initWithComponentType:(OSType)componentType andComponentSubType:(OSType)componentSubType {
	return [self init];
}

-(id)initWithSampleRate:(Float64)rate {
	self = [super initWithComponentType:kAudioUnitType_Mixer andComponentSubType:kAudioUnitSubType_MultiChannelMixer];
	if (self) {
        attachCallbacks = YES;
		numberOfBuses = -1;
		sampleRate = rate;
	}
	return self;
}

#pragma mark -
#pragma mark Deallocate

-(void)dealloc {
	numberOfBuses = -1;
    if (soundStructArray) {
        [self deallocAllSamples];
        free(soundStructArray);
    }
}

-(void)deallocAllSamples {
	for (int i = 0; i < numberOfBuses; i++) {
		[self deallocSampleWithIndex:i];
	}
}

-(void)deallocSampleWithIndex:(NSUInteger)index {
	if (soundStructArray[index].audioDataLeft != NULL) {
		free (soundStructArray[index].audioDataLeft);
		soundStructArray[index].audioDataLeft = 0;
	}
	
	if (soundStructArray[index].audioDataRight != NULL) {
		free (soundStructArray[index].audioDataRight);
		soundStructArray[index].audioDataRight = 0;
	}
}

#pragma mark -

-(NSString*)description {
	return [NSString stringWithFormat:@"Mixer Unit (Node: %ld, Unit: %d)", self.node, (int)self.unit];
}

@end