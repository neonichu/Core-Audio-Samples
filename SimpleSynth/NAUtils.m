//
//  NAUtils.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NADescription.h"
#import "NAUtils.h"

static char *FormatError(char *str, OSStatus error) {
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	
	// see if it appears to be a 4-char-code
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
	}
    
	return str;
}

#pragma mark -

@implementation NAUtils

- (id)init
{
    return nil;
}

+ (BOOL)printErrorMessage:(NSString*)errorString withStatus:(OSStatus)result 
{
	if (noErr == result) return NO;
	
	char* resultString = (char *)malloc(7 * sizeof(char));
	resultString = FormatError(resultString, result);
	
	NSLog(@"*** %@ error: %s", errorString, resultString);
	free(resultString);
	
	return YES;
}

+ (NASoundStructPtr)readAudioFile:(NSURL*)fileUrl sampleRate:(Float64)sampleRate {
    NASoundStructPtr soundStruct = (NASoundStructPtr)malloc(sizeof(NASoundStructPtr));
    
	ExtAudioFileRef audioFileObject = 0;
	
	OSStatus result = ExtAudioFileOpenURL((__bridge CFURLRef)fileUrl, &audioFileObject);
	if ([self printErrorMessage:@"ExtAudioFileOpenURL" withStatus:result]) return NO;
	
	// Get the audio file's length in frames.
	UInt64 totalFramesInFile = 0;
	UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
	
	result =    ExtAudioFileGetProperty (
										 audioFileObject,
										 kExtAudioFileProperty_FileLengthFrames,
										 &frameLengthPropertySize,
										 &totalFramesInFile
										 );
	if ([self printErrorMessage:@"ExtAudioFileGetProperty (audio file length in frames)" withStatus:result]) return NO;
	
	// Assign the frame count to the soundStructArray instance variable
	soundStruct->frameCount = totalFramesInFile;
	soundStruct->isActive = YES;
	
	// Get the audio file's number of channels.
	AudioStreamBasicDescription fileAudioFormat = {0};
	UInt32 formatPropertySize = sizeof (fileAudioFormat);
	
	result =    ExtAudioFileGetProperty (
										 audioFileObject,
										 kExtAudioFileProperty_FileDataFormat,
										 &formatPropertySize,
										 &fileAudioFormat
										 );
	if ([self printErrorMessage:@"ExtAudioFileGetProperty (file audio format)" withStatus:result]) return NO;
	
	UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
	
	// Allocate memory in the soundStructArray instance variable to hold the left channel, or mono, audio data
	soundStruct->audioDataLeft =
	(AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
	
	AudioStreamBasicDescription importFormat = {0};
	if (2 == channelCount) {
		soundStruct->isStereo = YES;
		// Sound is stereo, so allocate memory in the soundStructArray instance variable to  hold the right channel audio data
		soundStruct->audioDataRight =
		(AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
		importFormat = [NADescription basicDescriptionForType:NADescriptionTypeStereo sampleRate:sampleRate];
	} else if (1 == channelCount) {
		soundStruct->isStereo = NO;
		importFormat = [NADescription basicDescriptionForType:NADescriptionTypeMono sampleRate:sampleRate];
	} else {
		NSLog (@"*** WARNING: File format not supported - wrong number of channels");
		ExtAudioFileDispose (audioFileObject);
		return NO;
	}
	
	// Assign the appropriate mixer input bus stream data format to the extended audio 
	//        file object. This is the format used for the audio data placed into the audio 
	//        buffer in the SoundStruct data structure, which is in turn used in the 
	//        inputRenderCallback callback function.
	
	result =    ExtAudioFileSetProperty (
										 audioFileObject,
										 kExtAudioFileProperty_ClientDataFormat,
										 sizeof (importFormat),
										 &importFormat
										 );
	if ([self printErrorMessage:@"ExtAudioFileSetProperty (client data format)" withStatus:result]) return NO;
	
	// Set up an AudioBufferList struct, which has two roles:
	//
	//        1. It gives the ExtAudioFileRead function the configuration it 
	//            needs to correctly provide the data to the buffer.
	//
	//        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so 
	//            that audio data obtained from disk using the ExtAudioFileRead function
	//            goes to that buffer
	
	// Allocate memory for the buffer list struct according to the number of channels it represents.
	AudioBufferList *bufferList;
	
	bufferList = (AudioBufferList *) malloc (
											 sizeof (AudioBufferList) + sizeof (AudioBuffer) * (channelCount - 1)
											 );
	
	if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return NO;}
	
	// initialize the mNumberBuffers member
	bufferList->mNumberBuffers = channelCount;
	
	// initialize the mBuffers member to 0
	AudioBuffer emptyBuffer = {0};
	size_t arrayIndex;
	for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
		bufferList->mBuffers[arrayIndex] = emptyBuffer;
	}
	
	// set up the AudioBuffer structs in the buffer list
	bufferList->mBuffers[0].mNumberChannels  = 1;
	bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
	bufferList->mBuffers[0].mData            = soundStruct->audioDataLeft;
    
	if (2 == channelCount) {
		bufferList->mBuffers[1].mNumberChannels  = 1;
		bufferList->mBuffers[1].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
		bufferList->mBuffers[1].mData            = soundStruct->audioDataRight;
	}
	
	// Perform a synchronous, sequential read of the audio data out of the file and
	//    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
	UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
	
	result = ExtAudioFileRead (
							   audioFileObject,
							   &numberOfPacketsToRead,
							   bufferList
							   );
	
	free (bufferList);
	
	if (noErr != result) {
		[self printErrorMessage:@"ExtAudioFileRead failure - " withStatus:result];
		
		// If reading from the file failed, then free the memory for the sound buffer.
		free (soundStruct->audioDataLeft);
		soundStruct->audioDataLeft = 0;
		
		if (2 == channelCount) {
			free (soundStruct->audioDataRight);
			soundStruct->audioDataRight = 0;
		}
		
		ExtAudioFileDispose (audioFileObject);            
		return NO;
	}
	
	// Set the sample index to zero, so that playback starts at the beginning of the sound.
	soundStruct->sampleNumber = 0;
	
	// Dispose of the extended audio file object, which also closes the associated file.
	ExtAudioFileDispose (audioFileObject);
    
	return soundStruct;
}

@end