//
//  NADescription.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NADescription.h"

static AudioStreamBasicDescription kNAStreamFormatDefault;
static AudioStreamBasicDescription kNAStreamFormatMono;
static AudioStreamBasicDescription kNAStreamFormatStereo;

#pragma mark -

@implementation NADescription

@synthesize description;

#pragma mark -

+ (AudioStreamBasicDescription)setupDefaultStereoHardwareDescriptor 
{
	AudioStreamBasicDescription result;
	
	size_t bytesPerSample = sizeof (AudioUnitSampleType);
	
    result.mFormatID          = kAudioFormatLinearPCM;
    result.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    result.mBytesPerPacket    = bytesPerSample;
    result.mFramesPerPacket   = 1;
    result.mBytesPerFrame     = bytesPerSample;
    result.mChannelsPerFrame  = 2;
    result.mBitsPerChannel    = 8 * bytesPerSample;
	
	return result;
}

+ (void)initialize 
{
	kNAStreamFormatStereo = [self setupDefaultStereoHardwareDescriptor];
	
	kNAStreamFormatMono = [self setupDefaultStereoHardwareDescriptor];
	kNAStreamFormatMono.mChannelsPerFrame = 1;
	
	kNAStreamFormatDefault = [self setupDefaultStereoHardwareDescriptor];
	kNAStreamFormatDefault.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	kNAStreamFormatDefault.mChannelsPerFrame = 1;
	kNAStreamFormatDefault.mBitsPerChannel = 16;
	kNAStreamFormatDefault.mBytesPerPacket = 2;
	kNAStreamFormatDefault.mBytesPerFrame = 2;
}

+ (AudioStreamBasicDescription)basicDescriptionForType:(NADescriptionType)type sampleRate:(Float64)sampleRate 
{
	AudioStreamBasicDescription description;
	
	switch (type) {
		case NADescriptionTypeMono:
			description = kNAStreamFormatMono;
			break;
		case NADescriptionTypeStereo:
			description = kNAStreamFormatStereo;
			break;
		case NADescriptionTypeDefault:
			description = kNAStreamFormatDefault;
			break;
		default:
			[NSException raise:@"Unsupported AudioDescriptionType" format:@"Format %d is unsupported.", type];
			break;
	}
	
	description.mSampleRate = sampleRate;
	
	return description;
}

#pragma mark -

- (id)initWithType:(NADescriptionType)type sampleRate:(Float64)sampleRate 
{
	self = [super init];
	if (!self) return nil;
	
	description = [[self class] basicDescriptionForType:type sampleRate:sampleRate];	
	
	return self;
}

@end