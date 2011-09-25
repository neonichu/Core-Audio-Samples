//
//  NADescription.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>

typedef enum {
	NADescriptionTypeMono			= 0,
	NADescriptionTypeStereo         = 1,
	NADescriptionTypeDefault        = 2
} NADescriptionType;

@interface NADescription : NSObject

@property (nonatomic, readonly) AudioStreamBasicDescription description;

+ (AudioStreamBasicDescription)basicDescriptionForType:(NADescriptionType)type sampleRate:(Float64)sampleRate;

- (id)initWithType:(NADescriptionType)type sampleRate:(Float64)sampleRate;

@end