//
//  NASession.m
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NANode.h"
#import "NASession.h"
#import "NAUtils.h"

#pragma mark Audio route change listener callback

// Audio session callback function for responding to audio route changes. If playing back audio and
//   the user unplugs a headset or headphones, or removes the device from a dock connector for hardware  
//   that supports audio playback, this callback detects that and stops playback. 
//
// Refer to AudioSessionPropertyListener in Audio Session Services Reference.
static void audioRouteChangeListenerCallback (
									   void                      *inUserData,
									   AudioSessionPropertyID    inPropertyID,
									   UInt32                    inPropertyValueSize,
									   const void                *inPropertyValue
									   ) {
    // Ensure that this callback was invoked because of an audio route change
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
	
    NASession *audioObject = (__bridge NASession*) inUserData;
    
    // if application sound is not playing, there's nothing to do, so return.
    if (!audioObject.isPlaying) {
        return;
	}
	
	// Determine the specific type of audio route change that occurred.
	CFDictionaryRef routeChangeDictionary = inPropertyValue;
	
	CFNumberRef routeChangeReasonRef =
	CFDictionaryGetValue (
						  routeChangeDictionary,
						  CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
						  );
	
	SInt32 routeChangeReason;
	
	CFNumberGetValue (
					  routeChangeReasonRef,
					  kCFNumberSInt32Type,
					  &routeChangeReason
					  );
	
	// "Old device unavailable" indicates that a headset or headphones were unplugged, or that 
	//    the device was removed from a dock connector that supports audio output. In such a case,
	//    pause or stop audio (as advised by the iOS Human Interface Guidelines).
	if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kNASessionPlaybackStateDidChangeNotification 
															object:audioObject]; 
	} 
}

#pragma mark -

@interface NASession()

@property (nonatomic, readwrite, assign) AUGraph processingGraph;
@property (nonatomic, readwrite, retain) NSMutableArray* audioUnits;
@property (nonatomic, readwrite, retain) NSMutableArray* connections;

@property (nonatomic, readwrite) BOOL interruptedDuringPlayback;

-(BOOL)openIfNeeded;
-(void)open;
-(void)close;

-(BOOL)initIfNeeded;
-(void)initGraph;
-(void)deinit;

@end


#pragma mark -

@implementation NASession

@synthesize audioUnits;
@synthesize connections;
@synthesize graphSampleRate;
@synthesize interruptedDuringPlayback;
@synthesize playing;
@synthesize processingGraph;

#pragma mark -
#pragma mark Initialize

-(BOOL)setupAudioSession {
	AVAudioSession* mySession = [AVAudioSession sharedInstance];
    [mySession setDelegate:self];
	
    NSError* audioSessionError = nil;
    
    if (![mySession setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError]) {
        NSLog (@"Error setting audio session category: %@", audioSessionError);
        return NO;
    }
	
    graphSampleRate = 44100.0;
    
    if (![mySession setPreferredHardwareSampleRate:graphSampleRate error:&audioSessionError]) {
        NSLog (@"Error setting preferred hardware sample rate: %@", audioSessionError);
        return NO;
    }
	
    if (![mySession setActive:YES error:&audioSessionError]) {
        NSLog (@"Error activating audio session during initial setup: %@", audioSessionError);
        return NO;
    }
	
    graphSampleRate = [mySession currentHardwareSampleRate];
	
    AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, (__bridge void*)self);
	
	return YES;
}

-(id)init {
	self = [super init];
	if (!self) return nil;
	
	if (![self setupAudioSession]) return nil;
	
	self.audioUnits = [NSMutableArray array];
	self.connections = [NSMutableArray array];
	
	OSStatus result = NewAUGraph (&processingGraph);
    if ([NAUtils printErrorMessage:@"NewAUGraph" withStatus:result]) return nil;
	
	return self;
}

#pragma mark -
#pragma mark Deallocate

-(void)dealloc {
	[self stop];
	[self deinit];
	[self close];
}

#pragma mark -
#pragma mark Manage graph and connections

-(BOOL)addNode:(NANode*)audioUnit {
	AUNode tempNode;
	
	AudioComponentDescription componentDescription = audioUnit.componentDescription;
    OSStatus result = AUGraphAddNode (processingGraph, &componentDescription, &tempNode);
	
	if ([NAUtils printErrorMessage:[NSString stringWithFormat:@"AUGraphNewNode failed for %@", audioUnit] 
						withStatus:result]) {
		return NO;
	}
	
	audioUnit.node = tempNode;
	[audioUnits addObject:audioUnit];
    return YES;
}

-(BOOL)removeNode:(NANode*)audioUnit {
    OSStatus result = AUGraphRemoveNode(processingGraph, audioUnit.node);
    
    if ([NAUtils printErrorMessage:[NSString stringWithFormat:@"AUGraphRemoveNode failed for %@", audioUnit] 
						withStatus:result]) {
		return NO;
	}
	
	[audioUnits removeObject:audioUnit];
    return YES;
}

-(BOOL)attachRenderNotifier:(AURenderCallback)renderCallback withUserData:(void*)userData {
	OSStatus result = AUGraphAddRenderNotify(processingGraph, renderCallback, userData);
	return ![NAUtils printErrorMessage:@"AUGraphAddRenderNotify" withStatus:result];
}

-(BOOL)connectNodeConnection:(AudioUnitNodeConnection)nodeConnection {
	OSStatus result = AUGraphConnectNodeInput (
											   processingGraph,
											   nodeConnection.sourceNode,
											   nodeConnection.sourceOutputNumber,
											   nodeConnection.destNode,
											   nodeConnection.destInputNumber
											   );
	
	NSString* errorMessage = [NSString stringWithFormat:@"AUGraphConnectNodeInput: from %d to %d", 
							  nodeConnection.sourceNode, nodeConnection.destNode];
	return ![NAUtils printErrorMessage:errorMessage withStatus:result];
}

-(BOOL)connectSourceNode:(NANode*)sourceUnit busNumber:(UInt32)sourceBusNumber
			toTargetNode:(NANode*)targetUnit busNumber:(UInt32)targetBusNumber {
	if (![self openIfNeeded]) return NO;
	
	AudioUnitNodeConnection connection = {0};
	connection.sourceNode = sourceUnit.node;
	connection.sourceOutputNumber = sourceBusNumber;
	connection.destNode = targetUnit.node;
	connection.destInputNumber = targetBusNumber;
	
	if (![self connectNodeConnection:connection]) {
		return NO;
	}
	
	[connections addObject:[NSValue value:&connection withObjCType:@encode(AudioUnitNodeConnection)]];
	
	return YES;
}

-(BOOL)disconnectFromTargetNode:(NANode*)targetUnit busNumber:(UInt32)targetBusNumber {
    OSStatus status = AUGraphDisconnectNodeInput(processingGraph,
                                                 targetUnit.node,
                                                 targetBusNumber);
    if ([NAUtils printErrorMessage:@"AUGraphDisconnectNodeInput" withStatus:status]) {
        return NO;
    }
    
    for (int i=0;i<[connections count];i++) {
		AudioUnitNodeConnection nodeConnection = {0};
		[[connections objectAtIndex:i] getValue:&nodeConnection];
		if (nodeConnection.destNode == targetUnit.node && nodeConnection.destInputNumber == targetBusNumber) {
            [connections removeObjectAtIndex:i];
            return YES;
        }
	}
    
    return YES;
}

-(void)clearConnections {
	OSStatus result = AUGraphClearConnections(processingGraph);
	[NAUtils printErrorMessage:@"AUGraphClearConnections" withStatus:result];
}

-(void)recreateConnections {
	for (NANode* audioUnit in audioUnits) {
		[audioUnit reattachCallbacks];
	}
	
	for (int i=0;i<[connections count];i++) {
		AudioUnitNodeConnection nodeConnection = {0};
		[[connections objectAtIndex:i] getValue:&nodeConnection];
		[self connectNodeConnection:nodeConnection];
	}
}

#pragma mark -
#pragma mark Open/Close do the memory management for the graph

-(BOOL)openIfNeeded {
	Boolean isOpen = false;
	OSStatus result = AUGraphIsOpen(processingGraph, &isOpen);
	
	if ([NAUtils printErrorMessage:@"AUGraphIsOpen" withStatus:result]) {
		return NO;
	}
	
	if (!isOpen) {
		[self open];
	}
	
	return YES;
}

-(void)open {
	OSStatus result = AUGraphOpen(processingGraph);
    [NAUtils printErrorMessage:@"AUGraphOpen" withStatus:result];
	
	for (int i = 0; i < [audioUnits count]; i++) {
		[[audioUnits objectAtIndex:i] initializeUnitForGraph:processingGraph];
	}
}

-(void)close {
	Boolean isOpen = false;
	OSStatus result = AUGraphIsOpen(processingGraph, &isOpen);
	[NAUtils printErrorMessage:@"AUGraphIsOpen" withStatus:result];
	
	if (isOpen) {
		result = AUGraphClose(processingGraph);
		[NAUtils printErrorMessage:@"AUGraphClose" withStatus:result];
	}
}

#pragma mark -
#pragma mark Setup the graph (connections, etc.)

-(BOOL)initIfNeeded {
	Boolean isInitialized = false;
	OSStatus result = AUGraphIsInitialized(processingGraph, &isInitialized);
	
	if ([NAUtils printErrorMessage:@"AUGraphIsInitialized" withStatus:result]) {
		return NO;
	}
	
	if (!isInitialized) {
		[self initGraph];
	}
	
	return YES;	
}

-(void)initGraph {
	if (![self openIfNeeded]) return;
	
    //CAShow (processingGraph);
	
    OSStatus result = AUGraphInitialize (processingGraph);
	[NAUtils printErrorMessage:@"AUGraphInitialize" withStatus:result];
}

-(void)deinit {
	Boolean isInitialized = false;
	OSStatus result = AUGraphIsInitialized(processingGraph, &isInitialized);
	[NAUtils printErrorMessage:@"AUGraphIsInitialized" withStatus:result];
	
	if (isInitialized) {
		result = AUGraphUninitialize (processingGraph);
		[NAUtils printErrorMessage:@"AUGraphUninitialize" withStatus:result];
	}
}

#pragma mark -
#pragma mark Start/Stop processing of the graph

-(void)start  {
	if (![self initIfNeeded]) return;
	
    OSStatus result = AUGraphStart (processingGraph);
    if (![NAUtils printErrorMessage:@"AUGraphStart" withStatus:result]) {
		self.playing = YES;
	}
}

-(void)stop {
    Boolean isRunning = false;
	
    OSStatus result = AUGraphIsRunning (processingGraph, &isRunning);
    [NAUtils printErrorMessage: @"AUGraphIsRunning" withStatus: result];
    
    if (isRunning) {
        result = AUGraphStop (processingGraph);
        [NAUtils printErrorMessage: @"AUGraphStop" withStatus: result];
		
        self.playing = NO;
    }
}

-(BOOL)update {
	Boolean isUpdated = false;
	OSStatus result = AUGraphUpdate(processingGraph, &isUpdated);
	[NAUtils printErrorMessage:@"AUGraphUpdate" withStatus:result];
	return isUpdated ? YES : NO;
}

#pragma mark -

-(NSString*)description {
	NSMutableString* description = [[NSMutableString alloc] init];
	for (NANode* audioUnit in audioUnits) {
		[description appendString:@"\t"];
		[description appendString:[audioUnit description]];
		[description appendString:@"\n"];
	}
	return description;
}

#pragma mark -
#pragma mark Audio Session Delegate Methods

// Respond to having been interrupted. This method sends a notification to the 
//    controller object, which in turn invokes the playOrStop: toggle method. The 
//    interruptedDuringPlayback flag lets the  endInterruptionWithFlags: method know 
//    whether playback was in progress at the time of the interruption.
-(void)beginInterruption {
    if (playing) {
        interruptedDuringPlayback = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kNASessionPlaybackStateDidChangeNotification
															object:self]; 
    }
}


// Respond to the end of an interruption. This method gets invoked, for example, 
//    after the user dismisses a clock alarm. 
-(void)endInterruptionWithFlags:(NSUInteger) flags {
    // Test if the interruption that has just ended was one from which this app 
    //    should resume playback.
    if (flags & AVAudioSessionInterruptionFlags_ShouldResume) {
        NSError *error = nil;
		
        if (![[AVAudioSession sharedInstance] setActive:YES error:&error]) {
            NSLog (@"Unable to reactivate the audio session after the interruption ended: %@", error);
        } else {
            if (self.interruptedDuringPlayback) {
                interruptedDuringPlayback = NO;
				
                [[NSNotificationCenter defaultCenter] postNotificationName:kNASessionPlaybackStateDidChangeNotification 
																	object: self];
            }
        }
    }
}

@end
