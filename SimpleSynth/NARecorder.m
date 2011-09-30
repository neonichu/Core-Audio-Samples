//
//  NARecorder.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NADescription.h"
#import "NARecorder.h"
#import "NAUtils.h"

@interface NARecorder ()

@property (nonatomic, assign) AudioStreamBasicDescription outputFormat;
@property (nonatomic, assign) BOOL shouldRecord;
@property (nonatomic, assign) ExtAudioFileRef extAudioFileRef;
@property (nonatomic, assign) Float64 sampleRate;
@property (nonatomic, copy) NSString* path;

@end

#pragma mark RemoteIO bus render callback

static OSStatus inputRenderCallback (
									 void                        *inRefCon,
									 AudioUnitRenderActionFlags  *ioActionFlags,
									 const AudioTimeStamp        *inTimeStamp,
									 UInt32                      inBusNumber,
									 UInt32                      inNumberFrames,
									 AudioBufferList             *ioData
									 ) 
{
	NARecorder* recorder = (__bridge NARecorder*)inRefCon;
	
	if (recorder.extAudioFileRef == NULL || !recorder.shouldRecord) {
		return noErr;
	}
	
	if (*ioActionFlags & kAudioUnitRenderAction_PostRender) {
		static int TEMP_kAudioUnitRenderAction_PostRenderError = (1 << 8);
		if (!(*ioActionFlags & TEMP_kAudioUnitRenderAction_PostRenderError)) {
			OSStatus err = ExtAudioFileWriteAsync(recorder.extAudioFileRef, 
												  inNumberFrames,
												  ioData);
			[NAUtils printErrorMessage:@"ExtAudioFileWriteAsync" withStatus:err];
		}
	}
	
    return noErr;
}

#pragma mark -

@implementation NARecorder

@synthesize extAudioFileRef;
@synthesize outputFormat;
@synthesize path;
@synthesize renderCallback;
@synthesize sampleRate;
@synthesize shouldRecord;

#pragma mark -
#pragma mark Initialize

-(id)init {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

-(id)initWithInputFormat:(AudioStreamBasicDescription)format sampleRate:(Float64)rate {
	self = [super init];
	if (!self) return nil;
	
	self.extAudioFileRef = NULL;
	self.outputFormat = format;
	self.sampleRate = rate;
    
	renderCallback = inputRenderCallback;
	
	return self;
}

#pragma mark -
#pragma mark Deallocate

-(void)dealloc {
	[self closeRecording];
}

#pragma mark -
#pragma mark Recording

-(void)closeRecording {
    self.shouldRecord = NO;
    
	if (self.extAudioFileRef) {
		OSStatus result = ExtAudioFileDispose(self.extAudioFileRef);
		[NAUtils printErrorMessage:@"ExtAudioFileDispose" withStatus:result];
		self.extAudioFileRef = NULL;
	}
}

-(BOOL)enableRecordingToPath:(NSString*)outputPath {
	if (self.outputFormat.mFormatID == 0) {
		[NSException raise:@"Cannot enable recording." format:@"Unsupported mixer output format."];
	}
    
	NSURL* outputFileUrl = [NSURL fileURLWithPath:outputPath];
	self.path = outputPath;
	
	AudioStreamBasicDescription temp = {0};
	temp.mChannelsPerFrame = 2;
	temp.mFormatID = kAudioFormatMPEG4AAC;
	temp.mSampleRate = self.sampleRate;
	
	UInt32 size = sizeof(temp);
	OSStatus err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &temp);
	if ([NAUtils printErrorMessage:@"AudioFormatGetProperty" withStatus:err]) return NO;
	
	err = ExtAudioFileCreateWithURL((__bridge CFURLRef)outputFileUrl,
									kAudioFileM4AType,
									&temp,
									NULL,
									kAudioFileFlags_EraseFile,
									&extAudioFileRef);
	
	if ([NAUtils printErrorMessage:@"ExtAudioFileCreateWithURL" withStatus:err]) return NO;
	
	err = ExtAudioFileSetProperty(self.extAudioFileRef,
								  kExtAudioFileProperty_ClientDataFormat,
								  sizeof(AudioStreamBasicDescription),
								  &outputFormat);
	if ([NAUtils printErrorMessage:@"ExtAudioFileSetProperty" withStatus:err]) return NO;
	
	err = ExtAudioFileWriteAsync(self.extAudioFileRef, 0, NULL);
	if ([NAUtils printErrorMessage:@"ExtAudioFileWriteAsync" withStatus:err]) return NO;
	
    self.shouldRecord = YES;
    
	return YES;
}

-(NSString*)pathToRecording {
	return self.path;
}

@end