//
//  NARecorder.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

@interface NARecorder : NSObject

@property (nonatomic, readonly) AURenderCallback renderCallback;

-(id)initWithInputFormat:(AudioStreamBasicDescription)format sampleRate:(Float64)rate;
-(NSString*)pathToRecording;

-(BOOL)enableRecordingToPath:(NSString*)outputPath;
-(void)closeRecording;

@end