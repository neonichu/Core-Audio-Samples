//
//  NAReverbEffect.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NANode.h"

@interface NAReverbEffect : NANode

@property (nonatomic, assign) float cutoff;
@property (nonatomic, assign) float resonance;
@property (nonatomic, assign) float sineFrequency;

@property (nonatomic, retain) NANode* inputNode;

@end