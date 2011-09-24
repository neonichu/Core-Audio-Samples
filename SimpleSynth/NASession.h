//
//  NASession.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define kNASessionPlaybackStateDidChangeNotification		@"NASessionPlaybackStateDidChangeNotification"

@class NANode;

@interface NASession : NSObject <AVAudioSessionDelegate>

@property (nonatomic, readonly) Float64 graphSampleRate;
@property (nonatomic, getter=isPlaying) BOOL playing;

-(BOOL)addNode:(NANode*)node;
-(BOOL)removeNode:(NANode*)node;

-(BOOL)attachRenderNotifier:(AURenderCallback)renderCallback withUserData:(void*)userData;

-(BOOL)connectSourceNode:(NANode*)sourceUnit busNumber:(UInt32)sourceBusNumber
			toTargetNode:(NANode*)targetUnit busNumber:(UInt32)targetBusNumber;
-(BOOL)disconnectFromTargetNode:(NANode*)targetUnit busNumber:(UInt32)targetBusNumber;

-(void)clearConnections;
-(void)recreateConnections;

-(void)start;
-(void)stop;
-(BOOL)update;

@end