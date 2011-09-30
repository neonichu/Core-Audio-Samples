//
//  NASineWave.h
//  SimpleSynth
//
//  Created by Boris Bügling on 17.06.11.
//  Copyright 2011 - All rights reserved.
//

#import "NANode.h"

@interface NASineWave : NANode

@property (nonatomic, assign) float frequency;

-(void)play;

@end