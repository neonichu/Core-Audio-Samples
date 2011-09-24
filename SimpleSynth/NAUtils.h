//
//  NAUtils.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

// Data structure for mono or stereo sound, to pass to the application's render callback function, 
//    which gets invoked by a Mixer unit input bus when it needs more audio to play.
typedef struct {
	BOOL                 isActive;		     // set to true if this sound is currently playing
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt32               frameCount;         // the total number of frames in the audio data
    UInt32               sampleNumber;       // the next audio sample to play
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
} NASoundStruct, *NASoundStructPtr;

@interface NAUtils : NSObject

+ (BOOL)printErrorMessage:(NSString*)errorString withStatus:(OSStatus)result;
+ (NASoundStructPtr)readAudioFile:(NSURL*)fileUrl sampleRate:(Float64)sampleRate;

@end
