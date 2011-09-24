//
//  NANode.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

@interface NANode : NSObject

@property (nonatomic, readonly) AudioComponentDescription componentDescription;

@property (nonatomic, readwrite) AUNode node;
@property (nonatomic, readwrite) AudioUnit unit;


-(id)initWithComponentType:(OSType)componentType andComponentSubType:(OSType)componentSubType;

-(void)initializeUnitForGraph:(AUGraph)graph;
-(void)reset;

-(BOOL)attachInputCallback:(AURenderCallback)renderCallback toBus:(UInt32)busNumber inGraph:(AUGraph)graph;
-(BOOL)attachRenderCallback:(AURenderCallback)renderCallback toBus:(UInt32 )busNumber inGraph:(AUGraph)graph;
-(BOOL)attachRenderNotifier:(AURenderCallback)renderCallback withUserData:(void*)userData;

-(void)reattachCallbacks;

-(AudioStreamBasicDescription)inputDescription;
-(AudioStreamBasicDescription)outputDescription;

-(Float64)outputSampleRate;

-(void)setInputFormat:(AudioStreamBasicDescription)format forBus:(UInt32)busNumber;
-(void)setOutputFormat:(AudioStreamBasicDescription)format forBus:(UInt32)busNumber;

-(void)setMaximumFramesPerSlice:(UInt32)maximumFramesPerSlice;
-(void)setOutputSampleRate:(Float64)sampleRate;

@end