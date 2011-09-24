//
//  NANode.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NANode.h"

#import "NACallback.h"
#import "NANode.h"
#import "NAUtils.h"

@interface NANode ()

@property (nonatomic, retain) NSMutableArray* callbacks;

@end

@implementation NANode

@synthesize callbacks;
@synthesize componentDescription;
@synthesize node;
@synthesize unit;

#pragma mark -
#pragma mark Initialize

-(id)initWithComponentType:(OSType)componentType andComponentSubType:(OSType)componentSubType {
	self = [super init];
	if (!self) return nil;
	
	callbacks = [NSMutableArray array];
	
	componentDescription.componentType = componentType;
	componentDescription.componentSubType = componentSubType;
	componentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	componentDescription.componentFlags = 0;
	componentDescription.componentFlagsMask = 0;
	
	return self;
}

// Override this method to initialize the AUNode for the AUGraph
-(void)initializeUnitForGraph:(AUGraph)graph {
	// Obtain the audio unit instance from its corresponding node.
	AudioUnit temp;
	OSStatus result = AUGraphNodeInfo (graph, self.node, NULL, &temp);
    if ([NAUtils printErrorMessage:@"AUGraphNodeInfo" withStatus:result]) {
		return;
	} else {
		self.unit = temp;
	}
}

#pragma mark -
#pragma mark Reset

-(void)reset {
	OSStatus result = AudioUnitReset(self.unit, kAudioUnitScope_Global, 0);
	[NAUtils printErrorMessage:@"AudioUnitReset" withStatus:result];
}

#pragma mark -
#pragma mark Attach callbacks

-(BOOL)attachAudioCallback:(NACallback*)callback {
	AURenderCallbackStruct renderCallbackStruct = callback.renderCallbackStruct;
	OSStatus result = noErr;
	
	switch (callback.callbackType) {
		case NAInputCallback:
			result = AUGraphSetNodeInputCallback (
												  callback.graph,
												  self.node,
												  callback.busNumber,
												  &renderCallbackStruct
												  );
			break;
		case NARenderCallback:
			result = AudioUnitSetProperty(self.unit, 
										  kAudioUnitProperty_SetRenderCallback,
										  kAudioUnitScope_Global,
										  callback.busNumber,
										  &renderCallbackStruct,
										  sizeof(renderCallbackStruct));
			break;
		default:
			[NSException raise:@"Unknown callback type" format:@"Unknown callback type %d", callback.callbackType];
			break;
	}
	
	return ![NAUtils printErrorMessage:@"AUGraphSetNodeInputCallback" withStatus:result];
}

-(BOOL)attachCallbackStruct:(AURenderCallbackStruct)renderCallbackStruct ofType:(NACallbackType)type 
					  toBus:(UInt32)busNumber inGraph:(AUGraph)graph {
	NACallback* callback = [[NACallback alloc] init];
	callback.busNumber = busNumber;
	callback.callbackType = type;
	callback.graph = graph;
	callback.renderCallbackStruct = renderCallbackStruct;
	
	BOOL result = [self attachAudioCallback:callback];
	
	if (result) {
		[callbacks addObject:callback];
	}
	
	return result; 
}

-(BOOL)attachCallback:(AURenderCallback)renderCallback ofType:(NACallbackType)type toBus:(UInt32)busNumber 
			  inGraph:(AUGraph)graph {
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = renderCallback;
	callbackStruct.inputProcRefCon  = (__bridge void*)self;
	return [self attachCallbackStruct:callbackStruct ofType:type toBus:busNumber inGraph:graph];
}

-(BOOL)attachInputCallback:(AURenderCallback)renderCallback toBus:(UInt32)busNumber inGraph:(AUGraph)graph {
	return [self attachCallback:renderCallback ofType:NAInputCallback toBus:busNumber inGraph:graph];
}

-(BOOL)attachRenderCallback:(AURenderCallback)renderCallback toBus:(UInt32 )busNumber inGraph:(AUGraph)graph {
	return [self attachCallback:renderCallback ofType:NARenderCallback toBus:busNumber inGraph:graph];
}

-(BOOL)attachRenderNotifier:(AURenderCallback)renderCallback withUserData:(void*)userData {
	OSStatus result = AudioUnitAddRenderNotify(self.unit, renderCallback, userData);
	return ![NAUtils printErrorMessage:@"AudioUnitAddRenderNotify" withStatus:result];
}

-(void)reattachCallbacks {
	for (NACallback* callback in callbacks) {
		[self attachAudioCallback:callback];
	}
}

#pragma mark -
#pragma mark Access stream descriptions

-(AudioStreamBasicDescription)descriptionForScope:(AudioUnitScope)scope {
	AudioStreamBasicDescription description;
	UInt32 size = sizeof(description);
	AudioUnitGetProperty(self.unit, kAudioUnitProperty_StreamFormat, scope, 0, &description, &size);
	return description;
}

-(AudioStreamBasicDescription)inputDescription {
	return [self descriptionForScope:kAudioUnitScope_Input];
}

-(AudioStreamBasicDescription)outputDescription {
	return [self descriptionForScope:kAudioUnitScope_Output];
}

#pragma mark -
#pragma mark Query bus characteristics

-(Float64)outputSampleRate {
	Float64 sampleRate;
	
	UInt32 size = sizeof(sampleRate);
	OSStatus result = AudioUnitGetProperty (
											self.unit,
											kAudioUnitProperty_SampleRate,
											kAudioUnitScope_Output,
											0,
											&sampleRate,
											&size
											);
	
	if ([NAUtils printErrorMessage:@"AudioUnitGetProperty (get audio unit output stream format)" withStatus:result]) {
		return -1;
	}
	
	return sampleRate;
}

#pragma mark -
#pragma mark Modify bus characteristics

-(void)setInputFormat:(AudioStreamBasicDescription)format forBus:(UInt32)busNumber {
    OSStatus result = AudioUnitSetProperty (
                                            self.unit,
                                            kAudioUnitProperty_StreamFormat,
                                            kAudioUnitScope_Input,
                                            busNumber,
                                            &format,
                                            sizeof (format)
                                            );
	[NAUtils printErrorMessage:@"AudioUnitSetProperty (set audio unit input bus stream format)" withStatus:result];
}

-(void)setOutputFormat:(AudioStreamBasicDescription)format forBus:(UInt32)busNumber {
    OSStatus result = AudioUnitSetProperty (
											self.unit,
											kAudioUnitProperty_StreamFormat,
											kAudioUnitScope_Output,
											busNumber,
											&format,
											sizeof (format)
											);
	[NAUtils printErrorMessage:@"AudioUnitSetProperty (set audio unit output bus stream format)" withStatus:result];
}

-(void)setMaximumFramesPerSlice:(UInt32)maximumFramesPerSlice {
    OSStatus result = AudioUnitSetProperty (
                                            self.unit,
                                            kAudioUnitProperty_MaximumFramesPerSlice,
                                            kAudioUnitScope_Global,
                                            0,
                                            &maximumFramesPerSlice,
                                            sizeof (maximumFramesPerSlice)
                                            );
	
    [NAUtils printErrorMessage:@"AudioUnitSetProperty (set maximum frames per slice)" withStatus:result];
}

-(void)setOutputSampleRate:(Float64)sampleRate {
    OSStatus result = AudioUnitSetProperty (
                                            self.unit,
                                            kAudioUnitProperty_SampleRate,
                                            kAudioUnitScope_Output,
                                            0,
                                            &sampleRate,
                                            sizeof (sampleRate)
                                            );
	[NAUtils printErrorMessage:@"AudioUnitSetProperty (set audio unit output stream format)" withStatus:result];
}

#pragma mark -
#pragma mark Debugging helpers

-(void)printACD:(AudioComponentDescription)acd {
	char formatIDString[5];
    formatIDString[4] = '\0';
	
	NSAssert(acd.componentType != 0, @"Component Type not set.");
	UInt32 formatID = CFSwapInt32HostToBig (acd.componentType);
    bcopy (&formatID, formatIDString, 4);
	NSLog (@"  Component Type:           %10s",    formatIDString);
	
	NSAssert(acd.componentSubType != 0, @"Component SubType not set.");
	formatID = CFSwapInt32HostToBig(acd.componentSubType);
	bcopy(&formatID, formatIDString, 4);
	NSLog (@"  Component SubType:        %10s",    formatIDString);
	
	NSAssert(acd.componentManufacturer != 0, @"Component Manufacturer not set.");
	formatID = CFSwapInt32HostToBig(acd.componentManufacturer);
	bcopy(&formatID, formatIDString, 4);
	NSLog (@"  Component Manufacturer:   %10s",    formatIDString);
	
	NSLog (@"  Component Flags:          %10lu",    acd.componentFlags);
	NSLog (@"  Component Flags Mask:     %10lu",    acd.componentFlagsMask);
}

// You can use this method during development and debugging to look at the
//    fields of an AudioStreamBasicDescription struct.
-(void)printASBD:(AudioStreamBasicDescription)asbd {
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lu",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10lu",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10lu",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10lu",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10lu",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10lu",    asbd.mBitsPerChannel);
}

@end