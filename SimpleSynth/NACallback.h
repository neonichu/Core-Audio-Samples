//
//  NACallback.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

typedef enum {
	NAInputCallback = 0,
	NARenderCallback = 1,
	NARenderNotifier = 2
} NACallbackType;

@interface NACallback : NSObject

@property (nonatomic, readwrite) AUGraph graph;
@property (nonatomic, readwrite) AURenderCallbackStruct renderCallbackStruct;
@property (nonatomic, readwrite) NACallbackType callbackType;
@property (nonatomic, readwrite) UInt32 busNumber;

@end